// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface ITwineL2Gateway {
    /**********
     * Errors *
     **********/

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /// @dev Thrown when the caller is not corresponding `L1TwineMessenger` or `L2TwineMessenger`.
    error ErrorCallerIsNotMessenger();

    /// @dev Thrown when the cross chain sender is not the counterpart gateway contract.
    error ErrorCallerIsNotCounterpartGateway();

    /// @notice Emitted when the `counterpart gateway`  is updated.
    /// @param chainId The id of a chain.
    /// @param oldCounterpartGateway The corresponding address of the old gateway.
    /// @param newCounterpartGateway The corresponding address of the new gateway.
    event SetCounterpartGateway(uint256 indexed chainId, string indexed oldCounterpartGateway, string indexed newCounterpartGateway);


    /*************************
     * Public View Functions *
     *************************/
    
    /// @notice The counterpart gateway
    function counterpartGateWay(uint256 chainId,string memory l1Token)external view returns (string memory);

    /// @notice The address of L1GatewayRouter/L2GatewayRouter contract.
    function router() external view returns (address);

    /// @notice The address of corresponding L1TwineMessenger/L2TwineMessenger contract.
    function messenger() external view returns (address);
}
