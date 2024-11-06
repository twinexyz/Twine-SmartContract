// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineMessenger} from "../libraries/ITwineMessenger.sol";
interface IL2TwineMessenger is ITwineMessenger {
    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is sent.
    /// @param sender The address of the sender who initiates the message.
    /// @param target The address of target contract to call.
    /// @param value The amount of value passed to the target contract.
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    /// @param message The calldata passed to the target contract.
    event SentMessage(
        address indexed sender,
        address indexed target,
        uint256 value,
        uint256 gasLimit,
        bytes message
    );

    /// @notice Emitted when consensus verificiation is successful
    event consensusVerified(bytes headers, bytes proof);

    /// @notice Emitted when the deposit is successful
    event L1Deposit(bytes[] depositTransactions,bytes proof);

    /// @notice Emitted when the forcedWithdrawal is successful
    event FrocedWithdrawal(bytes withdrawalTransaction, bytes proof);
}
