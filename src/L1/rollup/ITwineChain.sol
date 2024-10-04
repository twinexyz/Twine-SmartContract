// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITwineChain {

    /// @notice Rollup batch stored data
    /// @param batchNumber Rollup batch number
    /// @param batchHash Hash of L2 batch
    /// @param numberOfLayer1Txs Number of priority operations to be processed
    /// @param priorityOperationsHash Hash of all priority operations from this batch
    /// @param l2LogsTreeRoot Root hash of tree that contains L2 -> L1 messages from this batch
    /// @param timestamp Rollup batch timestamp, have the same format as Ethereum batch constant
    struct StoredBatchInfo {
        uint64 batchNumber;
        bytes32 batchHash;
        uint256 numberOfLayer1Txs;
        bytes32 priorityOperationsHash;
        bytes32 l2LogsTreeRoot;
        uint256 timestamp;
    }

    /// @notice Data needed to commit new batch
    /// @param batchNumber Number of the committed batch
    /// @param timestamp Unix timestamp denoting the start of the batch execution
    /// @param newStateRoot The state root of the full state tree
    /// @param numberOfLayer1Txs Number of priority operations to be processed
    /// @param priorityOperationsHash Hash of all priority operations from this batch
    struct CommitBatchInfo {
        uint64 batchNumber;
        uint64 timestamp;
        bytes32 newStateRoot;
        uint256 numberOfLayer1Txs;
        bytes32 priorityOperationsHash;
    }


    /// @return The latest finalized batch index.
    function lastFinalizedBatchIndex() external view returns (uint256);

    /// @param batchIndex The index of the batch.
    /// @return The batch hash of a committed batch.
    function committedBatches(uint256 batchIndex) external view returns (bytes32);

    /// @param batchIndex The index of the batch.
    /// @return The state root of a committed batch.
    function finalizedStateRoots(uint256 batchIndex) external view returns (bytes32);

    /// @param batchIndex The index of the batch.
    /// @return The message root of a committed batch.
    function withdrawRoots(uint256 batchIndex) external view returns (bytes32);

    /// @param batchIndex The index of the batch.
    /// @return Whether the batch is finalized by batch index.
    function isBatchFinalized(uint256 batchIndex) external view returns (bool);

    
    /// @notice Function called by the operator to commit new batches. It is responsible for:
    /// - Verifying the correctness of their timestamps.
    /// - Processing their L2->L1 logs.
    /// - Storing batch commitments.
    /// @param _lastCommittedBatchData Stored data of the last committed batch.
    /// @param _newBatchesData Data of the new batches to be committed.
    function commitBatches(
        StoredBatchInfo calldata _lastCommittedBatchData,
        CommitBatchInfo[] calldata _newBatchesData
    ) external;

    /// @notice Batches commitment verification.
    /// @dev Only verifies batch commitments without any other processing.
    /// @param _prevBatch Stored data of the last committed batch.
    /// @param _committedBatches Stored data of the committed batches.
    /// @param _proofBytes The encoded proof.
    /// @param _publicValues The encoded public values.
    function proveBatches(
        StoredBatchInfo calldata _prevBatch,
        StoredBatchInfo[] calldata _committedBatches,
        bytes calldata _publicValues, 
        bytes calldata _proofBytes
    ) external;
    
     /// @notice The function called by the operator to finalize (execute) batches. It is responsible for:
    /// - Processing all pending operations (commpleting priority requests).
    /// - Finalizing this batch (i.e. allowing to withdraw funds from the system)
    /// @param _batchesData Data of the batches to be executed.
    function executeBatches(StoredBatchInfo[] calldata _batchesData) external;

    /// @notice Reverts unexecuted batches
    /// @param _newLastBatch batch number after which batches should be reverted
    /// NOTE: Doesn't delete the stored data about batches, but only decreases
    /// counters that are responsible for the number of batches
    function revertBatches(uint256 _newLastBatch) external;
}