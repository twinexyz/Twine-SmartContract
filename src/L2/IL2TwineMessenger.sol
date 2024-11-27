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
    /// @param counterpartGateway The address of counterpart Messenger.
    /// @param value The amount of value passed to the target contract.
    /// @param chainId The chainId of L1
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    /// @param message The calldata passed to the target contract.
    event SentMessage(
        address indexed from,
        address to,
        address counterpartGateway,
        address counterpartMessenger,
        uint256 value,
        uint256 indexed chainId,
        uint256 blockNumber,
        uint256 gasLimit,
        bytes message
    );

    /// @notice Emitted when consensus verificiation is successful
    event consensusVerified(bytes consensusProof);

    /// @notice Emitted when L1 Token is deposited in L2
    event L1TokenDeposit();

    /// @notice Emitted when the forcedWithdrawal is successful
    /// @param from The address of the sender who initiates the message.
    /// @param to The address of the receiver
    /// @param counterpartGateway The address of counterpart Messenger.
    /// @param value The amount of value passed to the target contract.
    /// @param chainId The chainId of L1
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    /// @param message The calldata passed to the target contract.
    event ForcedWithdrawal(
        address indexed from,
        address to,
        address counterpartGateway,
        address counterpartMessenger,
        uint256 value,
        uint256 indexed chainId,
        uint256 blockNumber,
        uint256 gasLimit,
        bytes message
    );

    /// @notice Emitted when the Layerzero payload is successfully verified
    event LayerzeroPayload(
        uint32 indexed dstEid,
        address receiverAddress,
        bytes32 payloadHash,
        bytes packetHeader
    );

    struct WithdrawalDetails {
        address l1Token;
        address l2Token;
        address from;
        address to;
        uint256 amount;
        uint256 value;
    }

    struct PayloadDetails {
        uint32 dstEid;
        address receiverAddress;
        bytes32 payloadHash;
        bytes packetHeader;
    }
}
