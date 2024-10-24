// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineMessenger {

    enum TransactionType{
        deposit,
        withdrawal
    }

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Return the sender of a cross domain message.
    function xDomainMessageSender() external view returns (address);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Send cross chain message from L1 to L2 or L2 to L1.
    /// @param transactionType The type of transaction (deposit or withdrawal).
    /// @param target The address of account who receive the message.
    /// @param value The amount of ether passed when call target contract.
    /// @param message The content of the message.
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    function sendMessage(
        TransactionType transactionType,
        address target,
        uint256 value,
        bytes calldata message,
        uint256 gasLimit
    ) external payable;

    /// @notice Send cross chain message from L1 to L2 or L2 to L1.
    /// @param transactionType The type of transaction (deposit or withdrawal).
    /// @param target The address of account who receive the message.
    /// @param value The amount of ether passed when call target contract.
    /// @param message The content of the message.
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    /// @param from The address who is sending the transaction.
    function sendMessage(
        TransactionType transactionType,
        address target,
        uint256 value,
        bytes calldata message,
        uint256 gasLimit,
        address from
    ) external payable;
}
