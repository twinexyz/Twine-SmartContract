// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import {Types} from "../../libraries/rlp/Types.sol";


/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ContextUpgradeable, ITwineChain {
    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    ///@notice The chai ID for the L1 where this contract is deployed
    uint256 public chainID;

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

    /// @notice The mapping of batchNumber => CommittedBatches
    mapping(uint256 => StoredBatchInfo) public committedBatches;


    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;

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

    function setAddress(address _messageQueue, address _verifier) external {
        messageQueue = _messageQueue;
        verifier = _verifier;
    }

    // To be only called by prover
    function setProgramVKey(bytes32 _programVKey) external {
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
        bytes memory proofInput;
        bytes32 depositTransactionHash;
        bytes32[] memory otherTransactionHash;
        bytes32[] memory forcedTransactionHash;

        (proofInput,depositTransactionHash,otherTransactionHash,forcedTransactionHash)= _calculateProofInput(_newBatchData);

        return
            StoredBatchInfo({
                batchNumber: _newBatchData.batchNumber,
                batchHash: _newBatchData.batchHash,
                stateRoot: _newBatchData.stateRoot,
                transactionRoot: _newBatchData.transactionRoot,
                receiptRoot: _newBatchData.receiptRoot,
                depositTransactionHash: depositTransactionHash,
                forcedTransactionHashes: forcedTransactionHash,
                otherTransactionHashes: otherTransactionHash,
                publicInput: proofInput
            });
    }

    function _calculateProofInput(CommitBatchInfo memory _newBatchData)
        internal
        returns (bytes memory,bytes32,bytes32[] memory,bytes32[] memory)
    {
        bytes memory proofInput;
        bytes32 depositTransactionHash;
        bytes32[] memory otherTransactionHash;
        bytes32[] memory forcedTransactionHash;
        
        depositTransactionHash = _handleDeposit(_newBatchData.depositTransactionObject);
        forcedTransactionHash = _handleForcedTransaction(_newBatchData.forcedTransactionObjects);
        otherTransactionHash = _handleOtherTransaction(_newBatchData.otherTransactions);

        proofInput = abi.encodePacked(
            _newBatchData.batchNumber,
            _newBatchData.batchHash,
            _newBatchData.stateRoot,
            _newBatchData.transactionRoot,
            _newBatchData.receiptRoot,
            depositTransactionHash,
            forcedTransactionHash.length
        );

        for (uint256 i = 0; i < forcedTransactionHash.length; i++) {
            proofInput = abi.encodePacked(proofInput, forcedTransactionHash[i]);
        }

        // Append the number of `otherTransactionHash`
        proofInput = abi.encodePacked(proofInput, otherTransactionHash.length);
        
        // Append each `otherTransactionHash` element
        for (uint256 i = 0; i < otherTransactionHash.length; i++) {
            proofInput = abi.encodePacked(proofInput, otherTransactionHash[i]);
        }

        return (proofInput,depositTransactionHash,otherTransactionHash,forcedTransactionHash);
    }

    function _handleDeposit(TransactionObject memory _depositTransactionObject)
        internal  
        returns (bytes32) 
    {
        // Array that contains the receipt object for individual deposit Transactions
        Types.ReceiptObject[] memory depositReceiptObject = abi.decode(_depositTransactionObject.data, (Types.ReceiptObject[]));

        // loop to do processing on individual deposit receipt
        for(uint256 i = 0; i < depositReceiptObject.length; i++)  {
            Types.Receipt memory depositReceipts = depositReceiptObject[i].receipt;

            // Extract the datas from the log
            ReceiptData memory receiptData = abi.decode(depositReceipts.logs[0].logData.data, (ReceiptData));
            uint256 messageIndex = 0;

            // Check to see if the message was initiated from this L1
            if(receiptData.chainID == chainID) {
                //Extract the ith transaction from deposit Queue
                bytes memory dataFromQueue = IL1MessageQueue(messageQueue).getCrossDomainDepositMessage(messageIndex);

                // Pop the first Element from the Queue
                IL1MessageQueue(messageQueue).popFirstDepositElement();

                // Replace the _data with the transaction from Queue
                receiptData.data = dataFromQueue;  
                depositReceipts.logs[0].logData.data = abi.encode(receiptData);
                depositReceiptObject[i].receipt = depositReceipts;
                messageIndex += 1;
            }                 

        }
        // Replace the data field with the modified one.
        _depositTransactionObject.data = (abi.encode(depositReceiptObject));
        bytes32 depositTransactionHash = keccak256(abi.encode(_depositTransactionObject));
        return depositTransactionHash;
    }

    function _handleForcedTransaction(TransactionObject[] memory _forcedTransactionObject) 
        internal  
        returns (bytes32[] memory)
    {
        bytes32[] memory forcedTransactionHash;

        // For individual forced transaction object
        for(uint256 i = 0; i < _forcedTransactionObject.length; i++) {
            Types.ReceiptObject memory withdrawalReceipt =  abi.decode(_forcedTransactionObject[i].data, (Types.ReceiptObject));
            Types.Receipt memory receipt = withdrawalReceipt.receipt;

             // Extract the datas from the log
            ReceiptData memory receiptData = abi.decode(receipt.logs[0].logData.data, (ReceiptData));
            uint256 messageIndex = 0;

            // Check to see if the message was initiated from this L1
            if(receiptData.chainID == chainID) {
                //Extract the ith transaction from withdrawal Queue
                bytes memory dataFromQueue = IL1MessageQueue(messageQueue).getCrossDomainWithdrawalMessage(messageIndex);

                // Pop the first Element from the Queue
                IL1MessageQueue(messageQueue).popFirstWithdrawalElement();
                // Replace the _data with the transaction from Queue  
                receiptData.data = dataFromQueue;
                receipt.logs[0].logData.data = abi.encode(receiptData);
                withdrawalReceipt.receipt = receipt;
                messageIndex += 1;
            }  
            // Replace the data field with the modified one.

            _forcedTransactionObject[i].data = (abi.encode(withdrawalReceipt));
            forcedTransactionHash[i] = keccak256(abi.encode(_forcedTransactionObject[i])); 
        }            
        return forcedTransactionHash;
    }

    function _handleOtherTransaction(TransactionObject[] memory _otherTransactionObject)
        internal 
        pure 
        returns (bytes32[] memory) 
    {
        bytes32[] memory otherTransactionHash;    
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