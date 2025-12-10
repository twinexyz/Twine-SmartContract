// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineL1MessengerBase {
    /*********
     * Enums *
     *********/
    /// @notice Types of transactions to send as message
    /// @param deposit Deposit Transactions
    /// @param withdraw Withdraw Transactions
    enum TransactionType {
        deposit,
        withdrawal
    }

    /**********
     * Errors *
     **********/
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
    /// @notice Forward the message to be appended to the queue
    /// @param _type the type of a transaction
    /// @param l1_token l1 token to deposit/withdraw
    /// @param l2_token l2 token to receive/withdraw 
    /// @param amount amount to withdraw/deposit 
    function sendMessage(
        TransactionType _type,
        address from,
        address to,
        address l1_token,
        address l2_token,
        uint256 amount,
        bytes memory message
    ) external payable;
}
