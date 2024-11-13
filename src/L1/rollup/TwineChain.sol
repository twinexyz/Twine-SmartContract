// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {Types} from "../../libraries/rlp/Types.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";

/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ContextUpgradeable, ITwineChain {
    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    ///@notice The chai ID for the L1 where this contract is deployed
    uint256 public chainId;

    /// @notice The verification key.
    bytes32 public ProgramVKey;

    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

    /// @notice The address of RollupVerifier.
    address public verifier;

    /// @notice The Number of Last Batch Committed
    uint256 public override lastCommittedBatchNumber;

    /// @notice The Number of Last Batch Finalized
    uint256 public override lastFinalizedBatchNumber;

    /// @notice The number of deposit Transaction of this L1 that is committed but not finalized.
    uint256 public depositTransactionsCommitted;

    /// @notice The number of forced Transaction of this L1 that is committed but not finalized
    uint256 public forcedTransactionsCommitted;

    /// @notice Address of the rolemanager contract
    address roleManagerAddress;

    
    /// @notice The mapping of batchNumber => CommittedBatches
    mapping(uint256 => StoredBatchInfo) public committedBatches;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManagerAddress).checkRole(role, _msgSender());
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
    function initialize(address _messageQueue, address _verifier)
        external
        initializer
    {
        messageQueue = _messageQueue;
        verifier = _verifier;
    }

    function setMessengerQueueAddress(
        address _messageQueue
    ) external onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN()) {
        messageQueue = _messageQueue;
    }

    function setVeriferAddress(address _verifier) external onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN()) {
        verifier = _verifier;
    }

    function setProgramVKey(bytes32 _programVKey) external onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN()) {
        ProgramVKey = _programVKey;
    }

    /// @inheritdoc ITwineChain
    function commitBatch(CommitBatchInfo calldata _newBatchData) external {
        require(_newBatchData.batchNumber == lastCommittedBatchNumber + 1, "Only next batch can be committed.");
        StoredBatchInfo memory batchToCommit = _commitBatch(_newBatchData);
        committedBatches[batchToCommit.batchNumber] = batchToCommit;
        lastCommittedBatchNumber = batchToCommit.batchNumber;
    }

    function _commitBatch(CommitBatchInfo calldata _newBatchData) internal returns (StoredBatchInfo memory) {
       CommitmentData memory commitmentData = _calculateProofInput(_newBatchData);

        return
            StoredBatchInfo({
                batchNumber: _newBatchData.batchNumber,
                batchHash: _newBatchData.batchHash,
                stateRoot: _newBatchData.stateRoot,
                transactionRoot: _newBatchData.transactionRoot,
                receiptRoot: _newBatchData.receiptRoot,
                numberOfDepositTransaction: commitmentData._numberOfDepositTransactions,
                depositTransactionHash: commitmentData._depositTransactionHash,
                numberOfForcedTransaction: commitmentData._numberOfForcedTransactions,
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
        bytes32 depositTransactionHash;
        bytes32[] memory otherTransactionHash;
        bytes32[] memory forcedTransactionHash;
        uint256 numberOfDepositTransactions;
        uint256 numberOfForcedTransactions;
        
        if(_newBatchData.depositTransactionObject.length == 0){
            depositTransactionHash = bytes32(0);
        } else {
            (numberOfDepositTransactions, depositTransactionHash) = _handleDeposit(_newBatchData.depositTransactionObject[0]);
        }
        (numberOfForcedTransactions, forcedTransactionHash) = _handleForcedTransaction(_newBatchData.forcedTransactionObjects);
        otherTransactionHash = _handleOtherTransaction(_newBatchData.otherTransactions);

        proofInput = abi.encode(
            _newBatchData.batchNumber,
            _newBatchData.batchHash,
            _newBatchData.stateRoot,
            _newBatchData.transactionRoot,
            _newBatchData.receiptRoot,
            depositTransactionHash,
            forcedTransactionHash.length
        );

        for (uint256 i = 0; i < forcedTransactionHash.length; i++) {
            proofInput = abi.encode(proofInput, forcedTransactionHash[i]);
        }

        // Append the number of `otherTransactionHash`
        proofInput = abi.encode(proofInput, otherTransactionHash.length);
        
        // Append each `otherTransactionHash` element
        for (uint256 i = 0; i < otherTransactionHash.length; i++) {
            proofInput = abi.encode(proofInput, otherTransactionHash[i]);
        }

        CommitmentData memory commitData = CommitmentData({
            _proofInput: proofInput,
            _numberOfDepositTransactions: numberOfDepositTransactions,
            _depositTransactionHash: depositTransactionHash,
            _numberOfForcedTransactions: numberOfForcedTransactions,
            _forcedTransactionHash: forcedTransactionHash,
            _otherTransactionHash: otherTransactionHash
        });

        return (commitData);
    }

    function _handleDeposit(TransactionObject memory _depositTransactionObject)
        internal  
        returns (uint256, bytes32) 
    {   
        uint256 numberOfDepositTransactions;
        // Array that contains the receipt object for individual deposit Transactions
        Types.ReceiptObject[] memory depositReceipts = abi.decode(_depositTransactionObject.input, (Types.ReceiptObject[]));

        // loop to do processing on individual deposit receipt
        for(uint256 i = 0; i < depositReceipts.length; i++)  {

            // Extract the datas from the log
            ReceiptData memory receiptData = abi.decode(depositReceipts[i].logs[0].data, (ReceiptData));
            uint256 messageIndex = depositTransactionsCommitted;

            // Check to see if the message was initiated from this L1
            if(receiptData.chainId == chainId) {
                //Extract the ith transaction from deposit Queue
                bytes memory dataFromQueue = IL1MessageQueue(messageQueue).getCrossDomainDepositMessage(messageIndex);

                // Increase the deposit transaction Committed count
                depositTransactionsCommitted += 1;
                // Count the number of deposit transaction for this L1
                numberOfDepositTransactions += 1;

                // Replace the _data with the transaction from Queue
                receiptData.data = dataFromQueue;  
                depositReceipts[i].logs[0].data = abi.encode(receiptData);
            }                 

        }

        // Replace the data field with the modified one.
        _depositTransactionObject.input = (abi.encode(depositReceipts));
        bytes32 depositTransactionHash = keccak256(abi.encode(_depositTransactionObject));
        return (numberOfDepositTransactions, depositTransactionHash);
    }

    function _handleForcedTransaction(TransactionObject[] memory _forcedTransactionObject) 
        internal  
        returns (uint256, bytes32[] memory)
    {
        uint256 numberOfForcedTransactions;
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

                // Increase the count for number of forced transaction from this L1
                numberOfForcedTransactions += 1;

                // Replace the _data with the transaction from Queue  
                receiptData.data = dataFromQueue;
                withdrawalReceipt.logs[0].data = abi.encode(receiptData);
            }  

            // Replace the data field with the modified one.
            _forcedTransactionObject[i].input = (abi.encode(withdrawalReceipt));
            forcedTransactionHash[i] = keccak256(abi.encode(_forcedTransactionObject[i])); 
        }            
        return (numberOfForcedTransactions, forcedTransactionHash);
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


    /// @inheritdoc ITwineChain
    function finalizeBatch(uint256 batchNumber, bytes calldata _proofBytes) external {
        require(isBatchCommitted(batchNumber), "Batch Needs to be committed before finalization");

        bytes memory publicValues = committedBatches[batchNumber].publicInput;
        ISP1Verifier(verifier).verifyProof(ProgramVKey, publicValues, _proofBytes);

        // remove first (depositTransactionsCommitted) elements from depositQueue
        uint256 numberOfDepositTransaction = committedBatches[batchNumber].numberOfDepositTransaction;
        IL1MessageQueue(messageQueue).popFirstNDepositElement(numberOfDepositTransaction);

        // subtract the finalized deposits transactions
        depositTransactionsCommitted -= numberOfDepositTransaction;

        // remove first (forcedTransactionsCommitted) elements from withdrawQueue
        uint256 numberOfForcedTransaction = committedBatches[batchNumber].numberOfForcedTransaction;
        IL1MessageQueue(messageQueue).popFirstNWithdrawalElement(numberOfForcedTransaction);

        // subtract the finalized forced transactions
        forcedTransactionsCommitted -= numberOfForcedTransaction;

        finalizedStateRoots[batchNumber] = committedBatches[batchNumber].stateRoot;
        lastFinalizedBatchNumber = batchNumber;
    }  

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
}
