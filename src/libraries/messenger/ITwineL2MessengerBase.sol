// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineL2MessengerBase {
    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /// @notice Emitted when the `counterpart` for a `chain` is updated.
    /// @param chainId The id of a chain.
    /// @param oldCounterpartMessenger The corresponding address of the old messenger.
    /// @param newCounterpartMessenger The corresponding address of the new messenger.
    event SetCounterpartMessenger(
        uint256 indexed chainId,
        address indexed oldCounterpartMessenger,
        address indexed newCounterpartMessenger
    );

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Send cross chain message from  L2 to L1.
    /// @param target The address of account who receive the message.
    /// @param value The amount of ether passed when call target contract.
    /// @param message The content of the message.
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    function sendMessage(
        address target,
        uint256 value,
        bytes calldata message,
        uint256 gasLimit
    ) external payable;

    /// @notice Send cross chain message from L2 to L1.
    /// @param target The address of contract who receive the message.
    /// @param value The amount of ether passed when call target contract.
    /// @param message The content of the message.
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    /// @param from The address who is sending the transaction.
    function sendMessage(
        address target,
        uint256 value,
        bytes calldata message,
        uint256 gasLimit,
        address from
    ) external payable;
}
