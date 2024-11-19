// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
 
import {SP1Verifier} from "@sp1-contracts/v3.0.0/SP1VerifierGroth16.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
 
import {ITwineChain} from "./ITwineChain.sol";
import {Types} from "../../libraries/rlp/Types.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {RLPDecodeStruct} from "../../libraries/rlp/RLPDecodeStruct.sol";
import {RLPEncodeStruct, Types} from "../../libraries/rlp/RLPEncodeStruct.sol";
 
/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ContextUpgradeable, ITwineChain {
    using RLPEncodeStruct for TransactionObject;
    using RLPEncodeStruct for Types.ReceiptObject;

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();
 
    /*************
     * Constants *
     *************/
 
    ///@notice The chai ID for the L1 where this contract is deployed
    uint256 public chainId;
 
    /// @notice The verification key.
    bytes32 public ProgramVKey;
 
    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;
 
    /// @notice The address of RollupVerifier.
    address public verifier;
 
    /// @notice Address of the rolemanager contract
    address roleManager;
 
    /*************
     * Variables *
     *************/
 
    /// @notice The Number of Last Batch Committed
    uint256 public override lastCommittedBatchNumber;
 
    /// @notice The Number of Last Batch Finalized
    uint256 public override lastFinalizedBatchNumber;
 
    /// @notice The number of deposit Transaction of this L1 that is committed but not finalized.
    uint256 public depositTransactionsCommitted;
 
    /// @notice The number of forced Transaction of this L1 that is committed but not finalized
    uint256 public forcedTransactionsCommitted;
 
 
    /*************
     * Mappings  *
     *************/
 
    /// @notice The mapping of batchNumber => CommittedBatches
    mapping(uint256 => StoredBatchInfo) public committedBatches;
 
    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;
 
    /**********************
     * Function Modifiers *
     **********************/
 
    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }
 
    /***************
     * Constructor *
     ***************/
 
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
 
    /// @notice Initialize the storage of TwineChain.
    /// @param _messageQueue The address of `L1MessageQueue` contract.
    /// @param _verifier The address of zkevm verifier contract.
    function initialize(address _messageQueue, address _verifier,address _roleManager)
        external
        initializer
    {
        messageQueue = _messageQueue;
        verifier = _verifier;
        roleManager = _roleManager;
    }
 
    /*************************
     * Public View Functions *
     *************************/
 
    /// @inheritdoc ITwineChain
    function isBatchFinalized(uint256 _batchNumber) public view override returns (bool)
    {
        return _batchNumber <= lastFinalizedBatchNumber;
    }
 
    function isBatchCommitted(uint256 _batchNumber) public view returns (bool)
    {
        return _batchNumber <= lastCommittedBatchNumber;
    }
 
    function getReceiptRoot(uint256 _batchNumber) public view returns (bytes32) {
        require(isBatchCommitted(_batchNumber), "Batch Needs to be commited");
        return committedBatches[_batchNumber].receiptRoot;
    }
 
    function getTransactinObjectRLP(
        ITwineChain.TransactionObject memory _transactionObject
    ) public pure returns (bytes32 transactionObjectHash) {
        uint8 transactionType = 2;
        bytes memory returnedRlp = abi.encodePacked(transactionType,_transactionObject.encodeTransactionObject());
        transactionObjectHash = keccak256(
            returnedRlp
        );
    }
 
    /*****************************
     * Public Mutating Functions *
     *****************************/
 
    function setMessengerQueueAddress(
        address _messageQueue
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        messageQueue = _messageQueue;
    }
 
    function setVeriferAddress(address _verifier) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        verifier = _verifier;
    }
 
    function setProgramVKey(bytes32 _programVKey) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        ProgramVKey = _programVKey;
    }
 
    /// @inheritdoc ITwineChain
    function commitBatch(CommitBatchInfo calldata _newBatchData) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        //require(isBatchFinalized(_newBatchData.batchNumber - 1), "Previous batch must be finalized.");
 
        StoredBatchInfo memory batchToCommit = _commitBatch(_newBatchData);
        committedBatches[batchToCommit.batchNumber] = batchToCommit;
        lastCommittedBatchNumber = batchToCommit.batchNumber;
    }
 
    /// @inheritdoc ITwineChain
    function finalizeBatch(uint256 batchNumber, bytes calldata _proofBytes) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        
        require(
            isBatchCommitted(batchNumber), 
            "Batch needs to be committed before finalization"
        );
 
        // require(
        //     committedBatches[lastFinalizedBatchNumber].stateRoot == committedBatches[batchNumber].previousStateRoot,
        //     "Only next batch can be finalized."
        // );
 
        bytes memory publicValues = committedBatches[batchNumber].publicInput;
 
        SP1Verifier(verifier).verifyProof(ProgramVKey, publicValues, _proofBytes);
 
        // remove first (depositTransactionsCommitted) elements from depositQueue
        //IL1MessageQueue(messageQueue).popFirstNDepositElement(depositTransactionsCommitted);
 
        // subtract the finalized deposits transactions
        //depositTransactionsCommitted = 0;
 
        // remove first (forcedTransactionsCommitted) elements from withdrawQueue
        //IL1MessageQueue(messageQueue).popFirstNWithdrawalElement(forcedTransactionsCommitted);
 
        // subtract the finalized forced transactions
        //forcedTransactionsCommitted -= 0;
 
        finalizedStateRoots[batchNumber] = committedBatches[batchNumber].stateRoot;
 
        lastFinalizedBatchNumber = batchNumber;
    }  
 
 
    /**********************
     * Internal Functions *
     **********************/
 
    function _commitBatch(CommitBatchInfo calldata _newBatchData) internal returns (StoredBatchInfo memory) {
       CommitmentData memory commitmentData = _calculateProofInput(_newBatchData);
        return
            StoredBatchInfo({
                batchNumber: _newBatchData.batchNumber,
                batchHash: _newBatchData.batchHash,
                previousStateRoot: _newBatchData.previousStateRoot,
                stateRoot: _newBatchData.stateRoot,
                transactionRoot: _newBatchData.transactionRoot,
                receiptRoot: _newBatchData.receiptRoot,
                depositTransactionHashes: commitmentData._depositTransactionHash,
                forcedTransactionHashes: commitmentData._forcedTransactionHash,
                otherTransactionHashes: commitmentData._otherTransactionHash,
                publicInput: commitmentData._proofInput
            });
    }   
 
    function _calculateProofInput(CommitBatchInfo memory _newBatchData)
        internal
        returns (CommitmentData memory)
    {
        bytes memory proofInput;
        bytes32[] memory depositTransactionHash;
        bytes32[] memory otherTransactionHash;
        bytes32[] memory forcedTransactionHash;
 
        proofInput = abi.encodePacked(
            _newBatchData.batchNumber,
            _newBatchData.batchHash,
            _newBatchData.previousStateRoot,
            _newBatchData.stateRoot,
            _newBatchData.transactionRoot,
            _newBatchData.receiptRoot
        );
        if(_newBatchData.depositTransactionObject.length != 0){
            depositTransactionHash = _handleDeposit(_newBatchData.depositTransactionObject);
            proofInput = abi.encodePacked(proofInput, depositTransactionHash);
        }
        proofInput = abi.encodePacked(proofInput, uint32(_newBatchData.forcedTransactionObjects.length));
        if(_newBatchData.forcedTransactionObjects.length != 0){
            forcedTransactionHash = _handleForcedTransaction(_newBatchData.forcedTransactionObjects);
            for (uint256 i = 0; i < forcedTransactionHash.length; i++) {
                proofInput = abi.encodePacked(proofInput, forcedTransactionHash[i]);
            }
        }
        // Append each `otherTransactionHash` element
        if(_newBatchData.otherTransactions.length != 0){
            otherTransactionHash = _handleOtherTransaction(_newBatchData.otherTransactions);
 
            for (uint256 i = 0; i < otherTransactionHash.length; i++) {
                proofInput = abi.encodePacked(proofInput, otherTransactionHash[i]);
            }
        }
        CommitmentData memory commitData = CommitmentData({
            _proofInput: proofInput,
            _depositTransactionHash: depositTransactionHash,
            _forcedTransactionHash: forcedTransactionHash,
            _otherTransactionHash: otherTransactionHash
        });
 
        return (commitData);
    }
 
 
    function _handleDeposit(TransactionObject[] memory _depositTransactionObject)
        internal 
        returns (bytes32[] memory) 
    {   
        bytes32[] memory depositTransactionHash = new bytes32[](_depositTransactionObject.length);
 
        // For individual deposit transaction object
        for(uint256 i = 0; i < _depositTransactionObject.length; i++) {
            (bytes memory trimmedInput,bytes memory removedInput) = _trimFourBytes(_depositTransactionObject[i].input);
            // Array that contains RLP encoded Receipt Object for Individual deposit object
            (bytes[] memory encodedReceiptObjects,bytes[] memory proofs) = abi.decode(trimmedInput, (bytes[], bytes[]));
            // Extract the datas from the log
            for(uint256 j = 0; j < encodedReceiptObjects.length; j++){
                Types.ReceiptWithoutTxType memory decodedReceipt = RLPDecodeStruct.decodeReceiptObject(_trimOneByte(encodedReceiptObjects[j]));
                IL1MessageQueue.MessageData memory dataFromQueue = IL1MessageQueue(messageQueue).getCrossDomainDepositMessage(depositTransactionsCommitted);
                    for(uint256 k = 0; k < decodedReceipt.logs.length; k++){
                        if(decodedReceipt.logs[k].logAddress == dataFromQueue.messageQueueAddress) {
                            decodedReceipt.logs[k].topics[1] = dataFromQueue.fromAddressHash;
                            decodedReceipt.logs[k].data =  dataFromQueue.dataValuesByte;
                             ++ depositTransactionsCommitted;
                        }
                    }
                encodedReceiptObjects[j]= getReceiptObjectRLP(decodedReceipt);
            }
            _depositTransactionObject[i].input = prependBytes(removedInput,abi.encode(encodedReceiptObjects,proofs));
            depositTransactionHash[i] = getTransactinObjectRLP( _depositTransactionObject[i]); 
        }
        return depositTransactionHash;
    }
 
    function _handleForcedTransaction(TransactionObject[] memory _forcedTransactionObject) internal returns (bytes32[] memory)
    {
        bytes32[] memory forcedTransactionHash = new bytes32[](_forcedTransactionObject.length);
 
        // // For individual forced transaction object
        for(uint256 i = 0; i < _forcedTransactionObject.length; i++) {
            Types.ReceiptWithoutTxType memory forcedWithdrawalReceipt = RLPDecodeStruct.decodeReceiptObject(_trimOneByte(_forcedTransactionObject[i].input)); 
            IL1MessageQueue.MessageData memory dataFromQueue = IL1MessageQueue(messageQueue).getCrossDomainWithdrawalMessage(forcedTransactionsCommitted);
            for (uint256 j=0;j<forcedWithdrawalReceipt.logs.length;j++){
                if(forcedWithdrawalReceipt.logs[j].logAddress == dataFromQueue.messageQueueAddress) {
                            forcedWithdrawalReceipt.logs[j].topics[1] = dataFromQueue.fromAddressHash;
                            forcedWithdrawalReceipt.logs[j].data =  dataFromQueue.dataValuesByte;
                            ++ forcedTransactionsCommitted;
                }   
            }
            _forcedTransactionObject[i].input = getReceiptObjectRLP(forcedWithdrawalReceipt);    
            forcedTransactionHash[i] = getTransactinObjectRLP((_forcedTransactionObject[i])); 
        }            
        return forcedTransactionHash;
    }
 
    function _handleOtherTransaction(TransactionObject[] memory _otherTransactionObject)
        internal 
        pure 
        returns (bytes32[] memory) 
    {
        bytes32[] memory otherTransactionHash = new bytes32[](_otherTransactionObject.length);    
        for(uint256 i = 0; i < _otherTransactionObject.length; i++){
            otherTransactionHash[i] = getTransactinObjectRLP((_otherTransactionObject[i]));
        }
        return otherTransactionHash;
    } 
 
    function prependBytes(
        bytes memory prefix,
        bytes memory originalData
    ) public pure returns (bytes memory) {
        require(prefix.length == 4, "Prefix must be exactly 4 bytes");
        bytes memory result = new bytes(prefix.length + originalData.length);
 
        for (uint256 i = 0; i < prefix.length; i++) {
            result[i] = prefix[i];
        }
        for (uint256 i = 0; i < originalData.length; i++) {
            result[i + prefix.length] = originalData[i];
        }
        return result;
    }
 
    function _trimFourBytes(bytes memory input) internal pure returns (bytes memory trimmedData,bytes memory removedBytes) {
        removedBytes = new bytes(4);
        for (uint256 i = 0; i < 4; i++) {
        removedBytes[i] = input[i];
        }
        trimmedData = new bytes(input.length - 4);
        for(uint256 i = 4; i < input.length; i++){
            trimmedData[i - 4] = input[i];
        }
    }
 
    function _trimOneByte(bytes memory input) internal pure returns (bytes memory) {
        bytes memory trimmedData = new bytes(input.length - 1);
        for(uint256 i = 1; i < input.length; i++){
            trimmedData[i - 1] = input[i];
        }
        return trimmedData;
    }

    function getReceiptObjectRLP(
        Types.ReceiptWithoutTxType memory _ro
    ) public pure returns (bytes memory) {
 
        Types.ReceiptObject memory ro = Types.ReceiptObject({
            txType: Types.TxType.Eip1559,
            success: _ro.success,
            cumulativeGasUsed: _ro.cumulativeGasUsed,
            bloom: _ro.bloom,
            logs: _ro.logs
        });
 
        return abi.encodePacked(ro.txType, ro.encodeReceiptObject());
    }     
}