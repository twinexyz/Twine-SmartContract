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

    /// @notice Emitted when the `counterpart gateway`  is updated.
    /// @param chainId The id of a chain.
    /// @param oldCounterpartGateway The corresponding address of the old gateway.
    /// @param newCounterpartGateway The corresponding address of the new gateway.
    event SetCounterpartGateway(uint256 indexed chainId, address indexed oldCounterpartGateway, address indexed newCounterpartGateway);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Send cross chain message from L2 to L1.
    /// @param from The address of the sender
    /// @param to The address of the receiver
    /// @param counterpart The address of counterpart gateway
    /// @param message The content of the message.
    /// @param value The amount of native token
    /// @param chainId The chainId of L1
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    /// @param from The address who is sending the transaction.
    function sendMessage(
        address from,
        address to,
        address counterpart,
        uint256 value,
        uint256 chainId,
        uint256 gasLimit,
        bytes calldata message
    ) external payable;
}
