// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";
interface IL2TwineMessenger is ITwineL2MessengerBase {
    enum TransactionType {
        BridgeTxns,
        LayerZeroDVN
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

    /// @notice Emitted when consensus verificiation is successful
    event consensusVerified(bytes consensusProof);

    /// @notice Emitted when L1 Token is deposited in L2
    event L1TokenDeposit();

    /// @notice Emitted when the forcedWithdrawal is successful
    /// @param from The address of the sender who initiates the message.
    /// @param to The address of the receiver
    /// @param value The amount of value passed to the target contract.
    /// @param chainId The chainId of L1
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    event ForcedWithdrawal(
        address indexed from,
        address l2Token,
        string to,
        string l1Token,
        uint256 amount,
        uint256 value,
        uint256 indexed chainId,
        uint256 blockNumber,
        uint256 gasLimit
    );

    /// @notice Emitted when the Layerzero payload is successfully verified
    event LayerzeroPayload(uint256 indexed sourceChainId, bytes32 indexed guId);

    event ParityHash(
        bytes32 parityHash,
        uint256 blockNumber,
        bytes32 blockHash
    );

    struct WithdrawalDetails {
        address l1Token;
        address l2Token;
        address from;
        address to;
        uint256 amount;
        uint256 value;
    }

    /// @notice set the precompile address.
    /// @param _consensusPrecompileAddress The address of the consensus precompile.
    /// @param _bridgingPrecompileAddress The address of the bridging Precompile.
    function setPrecompileAddress(
        address _consensusPrecompileAddress,
        address _bridgingPrecompileAddress
    ) external;

    /// @notice verify the consensus proof and execute deposits
    /// @param chainId The id of the chain
    /// @param slotNumber slot number of solana
    /// @param consensusProof consesus proof of the batch
    /// @param depositTransactions deposit transactions of the batch
    /// @param parityHash parity hash
    function verifyConsensusProofAndExecuteDeposit(
        uint256 chainId,
        uint256 slotNumber,
        bytes32 bankHash,
        bytes memory consensusProof,
        bytes memory depositTransactions,
        bytes32 parityHash
    ) external;

    /// @notice Execute forced withdrawal
    /// @param chainId The id of the chain
    /// @param withdrawalTransaction Transaction to execute the withdrawal
    function executeForcedWithdrawal(
        uint256 chainId,
        bytes memory withdrawalTransaction,
        bytes32 parityHash
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
