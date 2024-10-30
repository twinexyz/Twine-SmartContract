// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/// @title ITwineChain
/// @notice The interface for TwineChain
interface ITwineChain {
    /**********
     * Events *
     **********/

    /// @notice Emitted when a new batch is committed
    /// @param batchNumber The number of the batch
    /// @param batchHash The hash of the batch
    event CommitBatch(uint256 indexed batchNumber, bytes32 indexed batchHash);

    /// @notice revert a pending batch.
    /// @param batchNumber The number of the batch.
    /// @param batchHash The hash of the batch
    event RevertBatch(uint256 indexed batchNumber, bytes32 indexed batchHash);

    /// @notice Emitted when a batch is finalized
    /// @param batchNumber The number of the batch
    /// @param batchHash The hash of the batch
    /// @param stateRoot The state Root on layer 2 after this batch
    /// @param withdrawRoot The merkle root on layer2 after this batch
    event FinalizeBatch(uint256 indexed batchNumber, bytes32 indexed batchHash, bytes32 stateRoot, bytes32 withdrawRoot);

   struct Transaction{
        address from;
        address to;
        uint256 amount;
        bytes message;
    }

    struct TransactionObject{
        address from;
        address to;
        uint256 nonce;
        uint256 value;
        uint256 gasLimit;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes data;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }


    struct CommitBatchInfo{
        uint64 batchNumber;
        bytes32 batchHash;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
        TransactionObject depositTransactionObject;
        TransactionObject[] forcedTransactionObjects;
        TransactionObject[] otherTransactions;
    }

    struct StoredBatchInfo{
        uint64 batchNumber;
        bytes32 batchHash;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
        bytes32 depositTransactionHash;
        bytes32[] forcedTransactionHashes;
        bytes32[] otherTransactionHashes;
        bytes publicInput;
    }

    struct Log{
        address sender; // Address that emitted the log
        bytes32[] topics; // Indexed parameters from the event
        bytes data; // Non-indexed data associated with the event
    }

    struct ReceiptObject{
        bool status; // Status of the transaction ( 1 for success, 0 for failure)
        uint128 cumulativeGasUsed; // Total gas used for the transaction
        Log[] logs; // Array of logs generated during the transaction
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @return The latest finalized batch number.
    function lastFinalizedBatchNumber() external view returns (uint256);

     /// @return The latest committed finalized batch number.
    function lastCommittedBatchNumber() external view returns (uint256);

    /// @param batchNumber The number of the batch.
    /// @return The state root of a committed batch.
    function finalizedStateRoots(uint256 batchNumber) external view returns (bytes32);

    /// @param batchNumber The number of the batch.
    /// @return Whether the batch is finalized by batch number.
    function isBatchFinalized(uint256 batchNumber) external view returns (bool);

    /// @param batchNumber The number of the batch.
    /// @return The receiptRoot of the batch
    function getReceiptRoot(uint256 batchNumber) external view returns (bytes32);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Commit a batch of transactions on Layer 1.
    ///
    /// @param _newBatchData The struct containing the batch's information
    function commitBatch(CommitBatchInfo calldata _newBatchData) external;


    /// @notice Finalize a bath on Layer 1.
    ///
    /// @param _batchNumber The batchNumber of the batch to finalize
    /// @param _proofBytes The plonk proof for the proof of execution of L2 batch
    function finalizeBatch(uint256 _batchNumber, bytes calldata _proofBytes) external;
    
}