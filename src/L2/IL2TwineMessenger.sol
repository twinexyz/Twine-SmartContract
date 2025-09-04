// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TwineTypes} from "../libraries/types/TwineTypes.sol";
import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";
interface IL2TwineMessenger is ITwineL2MessengerBase {
    struct TokenTxn {
        address token;
        address receiver;
        bool deposit;
        uint256 amount;
    }
    struct ContractCall {
        address targetContract;
        uint64 value;
        bytes data;
    }
    struct L1Metadata {
        uint64 blockHeight;
        string fromAddress;
        string l1Token;
    }
    struct L1Txns {
        uint64 nonce;
        TokenTxn tokenTxn;
        L1Metadata l1Metadata;
        bytes contractCallData;
    }

    enum ChainType {
        Ethereum,
        Solana
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

    /// @notice Emitted when a deposit or withdraw handling is failed.
    /// @param reason The reason of failure
    event TransactionFailed(bytes reason);

    event L1TransactionsHandled(
        uint256 chainId,
        uint8 status,
        uint256 nonce,
        bytes transactionOutput
    );

    /// @notice Emitted when consensus verificiation is successful
    event ConsensusVerified(bytes consensusProof);

    /// @notice Emitted when the Layerzero payload is successfully verified
    event LayerzeroPayload(uint256 indexed sourceChainId, bytes32 indexed guId);
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
    /// @param consensusPrecompileAddress The address of the consensus precompile.
    /// @param bridgingPrecompileAddress The address of the bridging Precompile.
    function setPrecompileAddress(
        address consensusPrecompileAddress,
        address bridgingPrecompileAddress
    ) external;

    /// @notice handle the solana transactions
    function handleSolanaTransactions(
        uint256 chainId,
        bytes calldata precompileInput
    ) external;

    /// @notice handle the ethereum  transactions
    function handleEthereumProofAndTransactions(
        uint256 chainId,
        uint256 executionHeight,
        TwineTypes.MessageData memory messageData,
        bytes memory serializedProof
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
