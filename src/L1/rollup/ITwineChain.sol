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
    event FinalizeBatch(
        uint256 indexed batchNumber,
        bytes32 indexed batchHash,
        bytes32 stateRoot,
        bytes32 withdrawRoot
    );

    /**********
     * Errors *
     **********/

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /**********
     * Enums  *
     **********/
    /// @notice Types of transactions stored in the queue
    /// @param deposit Deposit Transactions
    /// @param withdraw Withdraw Transactions
    /// @param layerZero layer zero transactions
    enum TransactionType {
        deposit,
        withdraw,
        layerZero
    }

    /************
     * Structs  *
     ************/

    struct StoredBlockInfo {
        bytes32 previousHash;
        bytes32 blockHash;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
    }

    /// @notice Twine batch stored data
    /// @param startBlock start of the block
    /// @param endBlock end of the block
    /// @param batchHash Hash of Twine batch
    struct StoredBatchInfo {
        uint64 startBlock;
        uint64 endBlock;
        bytes32 batchHash;
    }

    struct CommitBatchInfo {
        uint64 startBlock;
        uint64 endBlock;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
    }

    struct CommitBlockInfo {
        uint64 blockNumber;
        bytes32 blockHash;
        bytes32 transactionRoot;
        bytes32 receiptRoot;
    }

    // struct StoredBatchInfo {
    //     uint64 batchNumber;
    //     bytes32 batchHash;
    //     bytes32 previousStateRoot;
    //     bytes32 stateRoot;
    //     bytes32 transactionRoot;
    //     bytes32 receiptRoot;
    // }

    /// @notice First 40 bytes of the transaction data commitment
    /// @param startBlock first block of the batch
    /// @param endBlock   last block of the batch
    /// @param transactionRoot Transaction root of the batch
    struct TransactionInfo {
        uint64 startBlock;
        uint64 endBlock;
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

    /// @notice Input required to finalize the withdrawal
    /// @param publicInput Public Input for the g16 proof
    /// @param inclusionProof groth16 proof for proving the withdrawal's inclusion
    struct FinalizeWithdrawalInput {
        WithdrawalPublicInput publicInput;
        bytes inclusionProof;
    }

    /// @notice required withdrawal data to execute withdrawal
    /// @param chainId chain id of the L1 to withdraw on
    /// @param batchNumber Twine batch number on which the withdrawal was initiated
    /// @param nonce nonce of the message
    /// @param isForced identifier for denoting forced withdrawal
    /// @param receiptRoot receipt root of the batch
    /// @param l1ReceiverAddress receiver address on l1
    /// @param l1TokenAddress address of token to be received on l1
    /// @param l2TokenAddress address of token withdrawan from l2
    /// @param amount amount of token to withdraw
    struct WithdrawalPublicInput {
        bytes32 receiptRoot;
        uint64 chainId;
        uint64 batchNumber;
        uint64 nonce;
        uint8 isForced;
        string l1ReceiverAddress;
        string l1TokenAddress;
        string l2TokenAddress;
        string amount;
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @return lastFinalizedBatchNumber batch number of latest finalized batch
    function lastFinalizedBlockNumber() external view returns (uint256);

    /// @return The latest committed finalized batch number.
    function lastCommittedBlockNumber() external view returns (uint256);

    /// @param batchId The id of the batch.
    /// @return stateRoot state root of the provided batch
    function finalizedStateRoots(
        bytes32 batchId
    ) external view returns (bytes32);

    /// @param batchId The id of the batch.
    /// @return IsFinalized weather the provided batch is finalized or not
    function isBatchFinalized(bytes32 batchId) external view returns (bool);

    /// @param batchNumber The number of the batch.
    /// @return receiptRoot receiptRoot of the provided batch
    // function getReceiptRoot(
    //     uint256 batchNumber
    // ) external view returns (bytes32);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice sets the chain id
    /// @param _chainId the chain id to set
    function setChainId(uint256 _chainId) external;

    /// @notice sets the role manager address
    /// @param _roleManagerAddress the address of role manager to set
    function setRoleManagerAddress(address _roleManagerAddress) external;

    /// @notice sets the messager queue address
    /// @param _messageQueue the address message queue of to set
    function setMessengerQueueAddress(address _messageQueue) external;

    /// @notice sets the verifier address
    /// @param _verifier the address of verifier to set
    function setVeriferAddress(address _verifier) external;

    /// @notice sets vkeys for different proofs.
    /// @param _executionVKey vKey for execution proof for a batch
    /// @param _inclusionVKey vKey for transaction proof of a batch
    /// @param _withdrawalVKey vKey for withdrawal proof
    function setProgramVKey(
        bytes32 _executionVKey,
        bytes32 _inclusionVKey,
        bytes32 _withdrawalVKey
    ) external;

    ///@notice sets the gateway addresses
    /// @param _ethGateway ETHGateway address to set
    /// @param _ERC20Gateway ERC2OGateway address to set
    function setGatewayAddress(
        address _ethGateway,
        address _ERC20Gateway
    ) external;

    /// @notice Commit and finalize a batch on Layer 1.
    /// @param commit_info The struct containing the batch's information
    /// @param execution_proof The execution proof for that batch
    // function commitAndFinalizeBatch(
    //     StoredBatchInfo memory commit_info,
    //     bytes memory execution_proof
    // ) external;

    /// @notice Finalize transaction data for a batch
    /// @param transaction_info The sturct containing batch's transaction information
    /// @param inclusion_proof The inclusion proof for that batch of transaction
    function commitAndFinalizeTransactions(
        bytes memory transaction_info,
        bytes memory inclusion_proof
    ) external;

    /// @notice Finalizes both l2 initiated and forced withdrawal of different tokens
    /// @param withdrawalInputs required withdrawal data to execute withdrawal
    function finalizeWithdrawal(
        FinalizeWithdrawalInput memory withdrawalInputs
    ) external;
}
