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

    /************
     * Structs  *
     ************/

    struct AccessList {
        address _address;
        bytes32[] storageKeys;
    }

    struct TransactionObject {
        uint256 chainId;
        uint256 nonce;
        uint256 maxPriorityFeePerGas;
        uint256 maxFeePerGas;
        uint256 gas;
        address to;
        uint256 value;
        bytes input;
        AccessList[] accesslist;
        uint64 v;
        bytes32 r;
        bytes32 s;
    }

    struct CommitBatchInfo{
        uint64 batchNumber;
        bytes32 batchHash;
        bytes32 previousStateRoot;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
        TransactionObject[] depositTransactionObject;
        TransactionObject[] forcedTransactionObjects;
        TransactionObject[] otherTransactions;
    }

    struct StoredBatchInfo{
        uint64 batchNumber;
        bytes32 batchHash;
        bytes32 previousStateRoot;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
        bytes32[] depositTransactionHashes;
        bytes32[] forcedTransactionHashes;
        bytes32[] otherTransactionHashes;
        bytes publicInput;
    }

    struct CommitmentData{
        bytes _proofInput;
        bytes32[] _depositTransactionHash;
        bytes32[] _forcedTransactionHash;
        bytes32[] _otherTransactionHash;
    }

    struct ReceiptData {
        address sender;
        address to;
        address target; 
        uint256 value;
        uint256 chainId;
        uint256 MessageIndex;
        uint256 gasLimit;
        bytes data;
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