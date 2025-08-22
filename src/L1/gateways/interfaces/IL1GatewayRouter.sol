// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL1GatewayRouter {
    /***********
     * Events  *
     ***********/
    /// @notice Emitted when the address of ETH Gateway is updated.
    /// @param oldETHGateway The address of the old ETH Gateway.
    /// @param newEthGateway The address of the new ETH Gateway.
    event SetETHGateway(
        address indexed oldETHGateway,
        address indexed newEthGateway
    );

    /// @notice Emitted when the address of default ERC20 Gateway is updated.
    /// @param oldDefaultERC20Gateway The address of the old default ERC20 Gateway.
    /// @param newDefaultERC20Gateway The address of the new default ERC20 Gateway.
    event SetDefaultERC20Gateway(
        address indexed oldDefaultERC20Gateway,
        address indexed newDefaultERC20Gateway
    );

    /// @notice Emitted when the `gateway` for `token` is updated.
    /// @param token The address of token updated.
    /// @param oldGateway The corresponding address of the old gateway.
    /// @param newGateway The corresponding address of the new gateway.
    event SetERC20Gateway(
        address indexed token,
        address indexed oldGateway,
        address indexed newGateway
    );

    /*****************
     * Custom Errors *
     *****************/
    /// @notice Thrown when zero address provided
    error ZeroAddress();

    /// @notice Thrown when a function is called while in a context when it should not be
    error OnlyNotInContext();

    /// @notice Thrown when a function is called outside of deposit context
    error OnlyInDepositContext();

    /// @notice Thrown when no gateway is available for the requested operation
    error NoGatewayAvailable();

    /// @notice Thrown when no ETH gateway is available for ETH-related operations
    error NoETHGatewayAvailable();

    /// @notice Thrown when array lengths or data sizes do not match expected values
    error LengthMismatch();

    /// @notice Thrown when attempting to access a function that is not accessible from the router
    error NotAccessibleFromRouter();

    /*************************
     * Public View Functions *
     *************************/
    /// @notice Return the corresponding gateway address for given token address.
    /// @param token The address of token to query.
    function getERC20Gateway(address token) external view returns (address);

    /*****************************
     * Public Mutating Functions *
     *****************************/
    /// @notice Request ERC20 token transfer from users to gateways.
    /// @param sender The address of sender to request fund.
    /// @param token The address of token to request.
    /// @param amount The amount of token to request.
    function requestERC20(
        address sender,
        address token,
        uint256 amount
    ) external returns (uint256);

    /// @notice Update the address of ETH gateway contract.
    /// @dev This function should only be called by chain admin.
    /// @param ethGateway The address to update.
    function setETHGateway(address ethGateway) external;

    /// @notice Update the address of Role manager contract.
    /// @dev This function should only be called by chain admin.
    /// @param roleManagerAddress The address to update.
    function setRoleManagerAddress(address roleManagerAddress) external;

    /// @notice Update the address of default ERC20 gateway contract.
    /// @dev This function should only be called by chain admin.
    /// @param defaultERC20Gateway The address to update.
    function setDefaultERC20Gateway(address defaultERC20Gateway) external;

    /// @notice Update the mapping from token address to gateway address.
    /// @dev This function should only be called by chain admin.
    /// @param tokens The list of addresses of tokens to update.
    /// @param gateways The list of addresses of gateways to update.
    function setERC20Gateway(
        address[] calldata tokens,
        address[] calldata gateways
    ) external;
}
