// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/// @title ITwineChain
/// @notice The interface for TwineChain
interface ITwineChain {
    /**********
     * Events *
     **********/

    /// @notice Emitted when a new batch is committed
    /// @param batchIndex The index of the batch
    /// @param batchHash The hash of the batch
    event CommitBatch(uint256 indexed batchIndex, bytes32 indexed batchHash);

    /// @notice revert a pending batch.
    /// @param batchIndex The index of the batch.
    /// @param batchHash The hash of the batch
    event RevertBatch(uint256 indexed batchIndex, bytes32 indexed batchHash);

    /// @notice Emitted when a batch is finalized
    /// @param batchIndex The index of the batch
    /// @param batchHash The hash of the batch
    /// @param stateRoot The state Root on layer 2 after this batch
    /// @param withdrawRoot The merkle root on layer2 after this batch
    event FinalizeBatch(uint256 indexed batchIndex, bytes32 indexed batchHash, bytes32 stateRoot, bytes32 withdrawRoot);

   struct Transaction{
        address from;
        address to;
        uint256 amount;
        bytes message;
    }

    struct TransactionObject{
        uint256 gas;
        address to;
        Transaction[] transactions;
        bytes signature;
        // .....
    }

    struct WithdrawalTransactionObject{
        uint256 gas;
        address to;
        Transaction transaction;
        bytes signature;
        // ....
    }

    struct CommitBatchInfo{
        uint256 batchNumber;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        TransactionObject depositTransactionObject;
        WithdrawalTransactionObject[] withdrawalTransactionObjects;
        uint256[] withdrawalStatus;
        TransactionObject[] otherTransactions;
    }

    struct StoredBatchInfo{
        uint256 batchNumber;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32[] depositTransactionHashes;
        bytes32[] withdrawalTransactionHashes;
        uint256[] withdrawalStatus;
        bytes32[] otherTransactionHashes;
        bytes publicInput;
    }


    /*************************
     * Public View Functions *
     *************************/

    /// @return The latest finalized batch index.
    function lastFinalizedBatchIndex() external view returns (uint256);

     /// @return The latest committed finalized batch index.
    function lastCommittedBatchIndex() external view returns (uint256);

    /// @param batchIndex The index of the batch.
    /// @return The batch hash of a committed batch.
    function committedBatches(uint256 batchIndex) external view returns (bytes32);

    /// @param batchIndex The index of the batch.
    /// @return The state root of a committed batch.
    function finalizedStateRoots(uint256 batchIndex) external view returns (bytes32);

    /// @param batchIndex The index of the batch.
    /// @return Whether the batch is finalized by batch index.
    function isBatchFinalized(uint256 batchIndex) external view returns (bool);

    /// @param batchNumber The index of the batch
    /// @param transactionHash The hash of the transaction 
    /// @param _fromL1 Represents weather the txn is initiated from L1 or L2
    /// @return Whether the batch contains the transaction or not
    function inTransactionList(uint256 batchNumber, bytes32 transactionHash, bool _fromL1) external view returns (bool);

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
