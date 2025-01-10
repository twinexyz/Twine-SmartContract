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

     struct StoredBatchInfo {
        uint64 batchNumber;
        bytes32 batchHash;
        bytes32 previousStateRoot;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
    }

    struct TransactionInfo {
        uint64 batchNumber;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
        ChainCommitment ethereum;
        ChainCommitment solana;
    }

    struct ChainCommitment {
        DepositReturn deposit;
        WithdrawReturn withdraw;
        bytes otherTransactions;
    }

    struct DepositReturn {
        uint64 depositCount;
        bytes32 depositRollingHash;
    }

    struct WithdrawReturn {
        uint64 withdrawCount;
        bytes32 withdrawRollingHash;
        string statusBit;
    }

    struct FinalizeInput {
        uint64 batchNumber;
        bytes executionProof;
        bytes inclusionProof;
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

    /// @notice Commit a batch of transactions on Layer 1.
    ///
    /// @param commit_info The struct containing the batch's information
    /// @param transaction_info The sturct containing the transactions info for a batch
    function commitBatch(StoredBatchInfo calldata commit_info, TransactionInfo calldata transaction_info) external;

    /// @notice Finalize a bath on Layer 1.
    ///
    /// @param finalizeInput The inputs required for batch finalization
    function finalizeBatch(FinalizeInput calldata finalizeInput) external;
    
}
