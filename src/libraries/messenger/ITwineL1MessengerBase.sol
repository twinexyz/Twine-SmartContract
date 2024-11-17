// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineL1MessengerBase {
    enum TransactionType {
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

    /// @notice Send cross chain message from L1 to L2.
    /// @param transactionType The type of transaction (deposit or withdrawal).
    /// @param counterpart The address of contract that receive the message.
    /// @param value The amount of ether passed when call target contract.
    /// @param message The content of the message.
    /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
    function sendMessage(
        TransactionType transactionType,
        address counterpart,
        address from,
        address to,
        uint256 value,
        uint256 gasLimit,
        bytes memory message
    ) external payable;
    
}
