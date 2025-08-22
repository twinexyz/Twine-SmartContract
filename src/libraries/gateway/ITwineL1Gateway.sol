// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineL1Gateway {
    /*****************
     * Custom Errors *
     *****************/
    /// @notice Thrown when zero address provided
    error ZeroAddress();

    /// @notice Thrown when amount is zero
    error ZeroAmount();

    /// @notice Thrown when insufficient gas value provided
    error InsufficientGasValue();

    /*********
     * Events *
     *********/

    event RoleManagerUpdated(
        address indexed oldRoleManager,
        address indexed newRoleManager
    );
    event GatewayRouterUpdated(
        address indexed oldRouter,
        address indexed newRouter
    );
    event MessengerUpdated(
        address indexed oldMessenger,
        address indexed newMessenger
    );
    event ChainIdUpdated(uint64 oldChainId, uint64 newChainId);

    /*************************
     * Public Functions *
     *************************/

    /// @notice The address of L1GatewayRouter contract.
    function gatewayRouter() external view returns (address);

    /// @notice The address of corresponding L1TwineMessenger/L2TwineMessenger contract.
    function messenger() external view returns (address);
}
