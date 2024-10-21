// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface ITwineGateway {
    /**********
     * Errors *
     **********/

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /// @dev Thrown when the caller is not corresponding `L1TwineMessenger` or `L2TwineMessenger`.
    error ErrorCallerIsNotMessenger();

    /// @dev Thrown when the cross chain sender is not the counterpart gateway contract.
    error ErrorCallerIsNotCounterpartGateway();

    /// @dev Thrown when TwineMessenger is not dropping message.
    error ErrorNotInDropMessageContext();

    /*************************
     * Public View Functions *
     *************************/

    /// @notice The address of corresponding L1/L2 Gateway contract.
    function counterpart() external view returns (address);

    /// @notice The address of L1GatewayRouter/L2GatewayRouter contract.
    function router() external view returns (address);

    /// @notice The address of corresponding L1TwineMessenger/L2TwineMessenger contract.
    function messenger() external view returns (address);
}
