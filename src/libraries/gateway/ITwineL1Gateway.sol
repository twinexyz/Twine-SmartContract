// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface ITwineL1Gateway {

    /*************************
     * Public View Functions *
     *************************/

    /// @notice The address of L1GatewayRouter/L2GatewayRouter contract.
    function gatewayRouter() external view returns (address);

    /// @notice The address of corresponding L1TwineMessenger/L2TwineMessenger contract.
    function messenger() external view returns (address);
}
