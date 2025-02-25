// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";
interface IL2TwineMessenger is ITwineL2MessengerBase {
    enum TransactionType {
        BridgeTxns,
        LayerZeroDVN
    }

    /// @notice All types of messages incoming from L1
    enum L1TxnType {
        Deposit,
        ForcedWithdraw,
        LayerZero,
        Message
    }

    /// @notice Emitted when a cross domain message is sent.
    /// @param from The address of the sender who initiates the message.
    /// @param to The address of the receiver
    /// @param value The amount of value passed to the target contract.
    /// @param chainId The chainId of L1
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    event SentMessage(
        address indexed from,
        address l2Token,
        string to,
        string l1Token,
        uint256 amount,
        uint256 value,
        uint256 nonce,
        uint256 indexed chainId,
        uint256 blockNumber,
        uint256 gasLimit
    );

    /// @notice Emitted when consenus  verification and transaction of solana are executed successfully
    event SolanaTransactionsHandled(bytes transactionOutput);

    /// @notice Emitted when consenus  verification and transaction of ethereum are executed successfully
    event EthereumTransactionsHandled(bytes transactionOutput);

    /// @notice Emitted when consensus verificiation is successful
    event ConsensusVerified(bytes consensusProof);

    /// @notice Emitted when L1 Token is deposited in L2
    event L1TokenDeposit();

    /// @notice Emitted when the forcedWithdrawal is successful
    /// @param to The address of the receiver
    /// @param from The address of the sender who initiates the message.
    /// @param l1Nonce The l1 nonce value.
    /// @param chainId The chainId of L1
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    event ForcedWithdrawal(
        address l2Token,
        uint256 amount,
        uint256 l1Nonce,
        uint256 indexed chainId,
        uint256 blockNumber,
        uint256 gasLimit,
        string l1Token,
        string indexed from,
        string indexed to
    );

    /// @notice Emitted when the Layerzero payload is successfully verified
    event LayerzeroPayload(uint256 indexed sourceChainId, bytes32 indexed guId);

    event ParityHash(
        bytes32 parityHash,
        uint256 blockNumber,
        bytes32 blockHash
    );

    struct SolanaVerifierPrecompileOutput {
        bytes publicValue;
        bytes proof;
        bytes transactionInput;
    }

    struct EthereumVerifierPrecompileOutput {
        bytes publicValue;
        bytes proof;
    }

    struct WithdrawalDetails {
        uint256 l1Nonce;
        uint256 amount;
        address l2Token;
        string l1Token;
        string from;
        string to;
    }

    /// @notice set the precompile address.
    /// @param _consensusPrecompileAddress The address of the consensus precompile.
    /// @param _bridgingPrecompileAddress The address of the bridging Precompile.
    function setPrecompileAddress(
        address _consensusPrecompileAddress,
        address _bridgingPrecompileAddress
    ) external;

    /// @notice handle the solana transactions
    function handleSolanaTransactions(
        uint256 chainId,
        bytes calldata precompileInput
    ) external;

    /// @notice handle the ethereum  transactions
    function handleEthereumProofAndTransactions(
        uint256 chainId,
        bytes memory consensusProof,
        bytes memory ethereumTransactions
    ) external;
    /// @notice verify the layerzero payload
    /// @param lzPayload layerzero payload
    /// @param payloadProof  proof of payload
    function verifyLayerZeroPayload(
        uint256 chainId,
        bytes memory lzPayload,
        bytes memory payloadProof
    ) external;
}
