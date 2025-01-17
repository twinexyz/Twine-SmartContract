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

    /**********
     * Enums  *
     **********/
    enum TransactionType {
        deposit,
        withdraw,
        layerZero
    }

    /************
     * Structs  *
     ************/

    /// @notice Twine batch stored data
    /// @param batchNumber Twine batch number
    /// @param batchHash Hash of Twine batch
    /// @param previousStateRoot State root of the previous Twine batch
    /// @param stateRoot State root of the current Twine batch
    /// @param transactionRoot Transaction root of the batch
    /// @param receiptRoot Receipt root of the batch
    struct StoredBatchInfo {
        uint64 batchNumber;
        bytes32 batchHash;
        bytes32 previousStateRoot;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
    }

    /// @notice First 40 bytes of the transaction data commitment
    /// @param batchNumber Twine batch number
    /// @param transactionRoot Transaction root of the batch
    struct TransactionInfo {
        uint64 batchNumber;
        bytes32 transactionRoot;
    }

    /// @notice Chain Specific data from the corresponding 120 bytes of transaction data commitment
    /// @param depositCount Number of deposit executed on the batch
    /// @param depositRollingHash Rolling hash of executed deposit
    /// @param withdrawCount Number of forced withdraws executed on the batch
    /// @param withdrawRollingHash Rolling hash of executed withdrawals
    /// @param lzTransactionCount Number of layer zero transactions on the batch
    /// @param lzTransactionRollingHash Rolling hash of executed layerZero transactions
    struct ChainCommitment {
        uint64 depositCount;
        bytes32 depositRollingHash;
        uint64 withdrawCount;
        bytes32 withdrawRollingHash;
        uint64 lzTransactionCount;
        bytes32 lzTransactionRollingHash;
    }

    struct FinalizeWithdrawalInput {
        WithdrawalPublicInput publicInput;
        bytes inclusionProof;
    }

    struct WithdrawalPublicInput {
        uint64 chainId;
        uint64 batchNumber;
        uint64 nonce;
        bytes32 receiptRoot;
        string l1ReceiverAddress;
        string l1TokenAddress;
        string l2TokenAddress;
        string amount;
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

    /// @notice Commit and finalize a batch on Layer 1.
    /// @param commit_info The struct containing the batch's information
    /// @param execution_proof The execution proof for that batch
    function commitAndFinalizeBatch(StoredBatchInfo memory commit_info, bytes memory execution_proof) external;

    /// @notice Finalize transaction data for a batch
    /// @param transaction_info The sturct containing batch's transaction information
    /// @param inclusion_proof The inclusion proof for that batch of transaction
    function commitAndFinalizeTransactions(bytes memory transaction_info, bytes memory inclusion_proof) external;
}
