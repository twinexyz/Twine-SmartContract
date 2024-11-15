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
    function isBatchFinalized(uint256 _batchNumber)
        public
        view
        override
        returns (bool)
    {
        return _batchNumber <= lastFinalizedBatchNumber;
    }

    function isBatchCommitted(uint256 _batchNumber)
        public
        view
        returns (bool)
    {
        return _batchNumber <= lastCommittedBatchNumber;
    }

    function getReceiptRoot(uint256 _batchNumber) public view returns (bytes32) {
        require(isBatchCommitted(_batchNumber), "Batch Needs to be commited");
        return committedBatches[_batchNumber].receiptRoot;
    }

    function getTransactinObjectRLP(
        ITwineChain.TransactionObject memory _transactionObject
    ) public view returns (bytes32 transactionObjectHash) {
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
                proofInput = abi.encode(proofInput, forcedTransactionHash[i]);
            }
        }

        // Append each `otherTransactionHash` element
        if(_newBatchData.otherTransactions.length != 0){
            otherTransactionHash = _handleOtherTransaction(_newBatchData.otherTransactions);

            for (uint256 i = 0; i < otherTransactionHash.length; i++) {
                proofInput = abi.encode(proofInput, otherTransactionHash[i]);
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
            // if(_depositTransactionObject[i].chainId == chainId){
            //     bytes memory trimmedInput = _trimFourBytes(_depositTransactionObject[i].input);
                 
            //      // Array that contains RLP encoded Receipt Object for Individual deposit object
            //     (bytes[] memory encodedReceiptObjects, ) = abi.decode(trimmedInput, (bytes[], bytes[]));

            //     // Extract the datas from the log
            //     for(uint256 j = 0; j < encodedReceiptObjects.length; j++){
            //         Types.ReceiptWithoutTxType memory decodedReceipt = RLPDecodeStruct.decodeReceiptObject(encodedReceiptObjects[j]);
            //         uint256 messageIndex = 0;

            //         bytes memory dataFromQueue = IL1MessageQueue(messageQueue).getCrossDomainDepositMessage(messageIndex);
            //         Types.LogData memory decodedDataFromQueue = abi.decode(dataFromQueue, (Types.LogData));
            //         depositTransactionsCommitted += 1;

            //         decodedReceipt.logs[0] = decodedDataFromQueue;
            //         bytes memory reencodedReceipt = getReceiptObjectRLP(decodedReceipt);
            //         _depositTransactionObject[i].input = reencodedReceipt;
            //     }
            // }
            depositTransactionHash[i] = getTransactinObjectRLP( _depositTransactionObject[i]); 
        }
        return depositTransactionHash;
    }

    function _handleForcedTransaction(TransactionObject[] memory _forcedTransactionObject) 
        internal  
        returns (bytes32[] memory)
    {
        bytes32[] memory forcedTransactionHash = new bytes32[](_forcedTransactionObject.length);

        // For individual forced transaction object
        for(uint256 i = 0; i < _forcedTransactionObject.length; i++) {
            Types.ReceiptObject memory withdrawalReceipt =  abi.decode(_forcedTransactionObject[i].input, (Types.ReceiptObject));
        
            // Extract the datas from the log
            ReceiptData memory receiptData = abi.decode(withdrawalReceipt.logs[0].data, (ReceiptData));
            uint256 messageIndex = forcedTransactionsCommitted;

            // Check to see if the message was initiated from this L1
            if(receiptData.chainId == chainId) {
                //Extract the ith transaction from withdrawal Queue
                bytes memory dataFromQueue = IL1MessageQueue(messageQueue).getCrossDomainWithdrawalMessage(messageIndex);

                // Increase the forced transactions committed count
                forcedTransactionsCommitted += 1;

                // Replace the _data with the transaction from Queue  
                receiptData.data = dataFromQueue;
                withdrawalReceipt.logs[0].data = abi.encode(receiptData);
            }  

            // Replace the data field with the modified one.
            _forcedTransactionObject[i].input = (abi.encode(withdrawalReceipt));
            forcedTransactionHash[i] = keccak256(abi.encode(_forcedTransactionObject[i])); 
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
            otherTransactionHash[i] = keccak256(abi.encode(_otherTransactionObject));
        }
        return otherTransactionHash;
    } 

    function perpendBytes(bytes memory original) public returns (bytes memory){
        bytes4 toPrepend = bytes4(SP1Verifier(verifier).VERIFIER_HASH());
        bytes memory result  = new bytes(toPrepend.length + original.length);

        // Copy `toPrepend` into the result array
        for (uint64 i = 0; i < toPrepend.length; i++) {
            result[i] = toPrepend[i];
        }
        
        // Copy the original bytes into the result array after `toPrepend`
        for (uint64 i = 0; i < original.length; i++) {
            result[toPrepend.length + i] = original[i];
        }
        
        return result;
    }

    function _trimFourBytes(bytes memory input) internal returns (bytes memory) {
        bytes memory trimmedData = new bytes(input.length - 4);
        for(uint256 i = 0; i < input.length; i++){
            trimmedData[i - 4] = input[i];
        }
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
