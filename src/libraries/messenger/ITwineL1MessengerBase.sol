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

    function sendMessage(
        TransactionType _type,
        address from,
        address to,
        address l1_token,
        address l2_token,
        uint256 amount
    ) external payable;
    
}
