// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ITwineChain
/// @notice The interface for TwineChain
interface ITwineChain {
    /***********
     * Enums   *
     ***********/
    /// @notice Types of transactions stored in the queue
    /// @param Deposit Deposit Transactions
    /// @param Withdraw Withdraw Transactions
    /// @param LayerZero layer zero transactions
    enum TransactionType {
        Deposit,
        Withdraw,
        LayerZero
    }

    /************
     * Structs  *
     ************/
    /// @notice Twine batch stored data
    /// @param batchNumber number of the batch
    /// @param executedMessageCount L1 message handled on twine chain
    /// @param batchHash Hash of Twine batch
    struct BatchInfo {
        uint64 batchNumber;
        uint64 executedMessageCount;
        bytes32 batchHash;
    }

    /// @notice Twine batch hash data
    /// @param domainId unique ID for
    /// @param prevBatchHash last finalized batch hash
    /// @param merkleRoot merkle root of state roots of blocks in that batch
    struct BatchHashData {
        uint64 domainId;
        bytes32 prevBatchHash;
        bytes32 merkleRoot;
    }

    struct MessageValues {
        uint64 nonce;
        uint64 chainId;
        uint64 blockNumber;
        string fromAddress;
        string toAddress;
        string l1Token;
        string l2Token;
        string amount;
        bytes message;
    }
    struct L1OriginTxPublicValues {
        bytes32 batchHash;
        uint64 batchNumber;
        TransactionType txnType;
        uint64 nonce;
        uint64 chainId;
        uint64 blockNumber;
        bytes32 messageHash;
        string fromAddress;
        string toAddress;
        string l1Token;
        string l2Token;
        string amount;
    }

    struct L2WithdrawValues {
        uint64 batchNumber;
        uint64 nonce;
        bytes32 batchHash;
        string to;
        string l1Token;
        string l2Token;
        string amount;
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
    /// @param blockNumber Twine block number
    /// @param nonce nonce of the message
    /// @param isForcedWithdrawal identifier for denoting forced withdrawal
    /// @param receiptRoot receipt root of the batch
    /// @param l1ReceiverAddress receiver address on l1
    /// @param l1TokenAddress address of token to be received on l1
    /// @param l2TokenAddress address of token withdrawan from l2
    /// @param amount amount of token to withdraw
    struct WithdrawalPublicInput {
        uint64 chainId;
        uint64 blockNumber;
        uint64 nonce;
        uint8 isForcedWithdrawal;
        bytes32 receiptRoot;
        string l1ReceiverAddress;
        string l1TokenAddress;
        string l2TokenAddress;
        string amount;
    }

    /***********
     * Events  *
     ***********/
    /// @notice Emitted when a new batch is committed
    /// @param batchNumber The number of the batch
    /// @param chainId The id of the chain
    /// @param batchHash The hash of the batch
    event CommitedBatch(
        uint64 indexed batchNumber,
        uint64 chainId,
        uint256 blockNumber,
        bytes32 batchHash
    );

    event L2WithdrawExecuted(
        uint64 nonce,
        string indexed l1Token,
        string l2Token,
        string indexed receiver,
        string indexed amount,
        uint256 blockNumber
    );

    /// @notice Emitted when a batch is finalized
    /// @param batchNumber The number of the batch
    /// @param messagesHandledOnTwine The total messages of L1 handled on twine
    /// @param batchHash The hash of the batch
    event FinalizedBatch(
        uint64 indexed batchNumber,
        uint64 indexed messagesHandledOnTwine,
        uint64 chainId,
        uint256 blockNumber,
        bytes32 batchHash
    );

    event RefundSuccessful(
        uint64 nonce,
        string l1Address,
        string L1TokenAddress,
        uint64 ChainId,
        string amount,
        uint64 blockNumber
    );

    event ForcedWithdrawalSuccessful(
        uint64 nonce, 
        string l1Address,
        string L1TokenAddress,
        uint64 chainId,
        string amount,
        uint64 blockNumber
    );

    /// @notice Emitted when vkeys are set
    event SetProgramVkey(
        bytes32 executionVKey,
        bytes32 inclusionVKey,
        bytes32 withdrawalVKey
    );

     /*****************
     * Custom Errors *
     *****************/
    /// @notice Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /// @notice Thrown when verification keys are zero
    error InvalidVerificationKeys();

    /// @notice Thrown when genesis block is already committed
    error GenesisBlockAlreadyCommitted();

    /// @notice Thrown when not at genesis state
    error NotAtGenesis();

    /// @notice Thrown when batch sequence is invalid
    error InvalidBatchSequence();

    /// @notice Thrown when batch must be finalized sequentially
    error BatchMustBeFinalizedSequentially();

    /// @notice Thrown when committed batch hash doesn't match
    error CommittedBatchHashMismatch();

    /// @notice Thrown when previous batch hash doesn't match
    error PreviousBatchHashMismatch();

    /// @notice Thrown when last finalized batch hash doesn't match
    error LastFinalizedBatchHashMismatch();

    /// @notice Thrown when message count is invalid
    error InvalidMessageCount();

    /// @notice Thrown when refund is already processed
    error RefundAlreadyProcessed();

    /// @notice Thrown when withdrawal is already processed
    error WithdrawalAlreadyProcessed();

    /// @notice Thrown when transaction is not deposit type
    error TransactionMustBeDepositType();

    /// @notice Thrown when transaction is not withdraw type
    error TransactionMustBeWithdrawType();

    /// @notice Thrown when batch is not finalized yet
    error BatchNotFinalizedYet();

    /// @notice Thrown when batch hash doesn't match finalized batch
    error BatchHashMismatch();

    /// @notice Thrown when message hash doesn't exist
    error MessageHashNotFound();

    /*************************
     * Public View Functions *
     *************************/
    /// @param batchNumber The id of the batch.
    /// @return IsFinalized weather the provided batch is finalized or not
    function isBatchFinalized(uint256 batchNumber) external view returns (bool);

    /// @return BatchNumber The batch number of latest committed batch
    function lastCommittedBatchNumber() external view returns (uint256);

    /// @return BlatchNumber The batch number of latest finalized batch
    function lastFinalizedBatchNumber() external view returns (uint256);

    /*****************************
     * Public Mutating Functions *
     *****************************/
    /// @notice sets the chain id
    /// @param _chainId the chain id to set
    function setChainId(uint64 _chainId) external;

    /// @notice sets the role manager address
    /// @param _roleManagerAddress the address of role manager to set
    function setRoleManagerAddress(address _roleManagerAddress) external;

    /// @notice sets the message handler address
    /// @param _messageHandler the address message queue of to set
    function setMessageHandlerAddress(address _messageHandler) external;

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

    /// @notice sets the gateway addresses
    /// @param _ethGateway ETHGateway address to set
    /// @param _ERC20Gateway ERC2OGateway address to set
    function setGatewayAddress(
        address _ethGateway,
        address _ERC20Gateway
    ) external;

    /// @notice sets the zk verfication status
    function setZkVerifcationStatus(bool status) external;

    /// @notice Sets block hash of the genesis block
    /// @param genesisBlockHash The hash of the genesis block
    function commitGenesisBlock(bytes32 genesisBlockHash) external;

    /// @notice Commits a batch
    function commitBatch(uint64 batchNumber, bytes32 batchHash) external;

    /// @notice Finalizes a batch
    function finalizeBatch(
        uint64 batchNumber,
        bytes calldata publicValues,
        bytes calldata executionProof
    ) external;

    /// @notice Processes a refund for a deposit transaction if the transaction fails in L2.
    /// @dev The function validates the given zk-proof (`refundProof`) against the public input (`publicValues`)
    ///      to determine refund eligibility
    /// @param publicValues Encoded public input data required to verify the refund proof.
    /// @param refundProof Zero-knowledge proof proving eligibility for a deposit refund.
    function refundDeposit(
        bytes calldata publicValues,
        bytes calldata refundProof
    ) external;

    /// @notice Executes a forced withdrawal operation after validating the provided evidence.
    /// @dev The function validates the given zk-proof (`withdrawProof`) against the public input (`publicValues`)
    ///      to determine withdraw eligibility
    /// @param publicValues Encoded public input data required to verify the withdrawal proof.
    /// @param withdrawalProof Zero-knowledge proof validating the forced withdrawal request.
    function executeForcedWithdrawal(
        bytes calldata publicValues,
        bytes calldata withdrawalProof
    ) external;

    /// @notice Executes a withdrawal operation after validating the provided evidence.
    /// @dev Validates the zero-knowledge proof  against the supplied public input
    ///      to authorize and process the withdrawal.
    /// @param publicValues Encoded public input data required to verify the withdrawal proof.
    /// @param withdrawProof Zero-knowledge proof or cryptographic proof validating the withdrawal request.
    function executeL2Withdraw(
        bytes calldata publicValues,
        bytes calldata withdrawProof
    ) external;
}
