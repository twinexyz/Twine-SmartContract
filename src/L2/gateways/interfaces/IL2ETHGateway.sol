// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL2ETHGateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for ERC20 token is updated.
    /// @param l2Token The address of corresponding ERC20 token in layer 2.
    /// @param oldL1Token The address of the old corresponding ERC20 token in layer 1.
    /// @param newL1Token The address of the new corresponding ERC20 token in layer 1.
    event EthTokenMappingUpdated(
        uint256 indexed chainId,
        address indexed l2Token,
        string indexed oldL1Token,
        string newL1Token
    );

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 2 to layer 1 token mapping.
    /// @dev To make the token mapping consistent with L1, this should be called from L1.
    /// @param l2Token The address of corresponding token on layer 2.
    /// @param l1Token The address of token on layer 1.
    ///@param chainId The chain Id of l1 Token.
    function updateTokenMapping(
        uint256 chainId,
        address l2Token,
        string memory l1Token
    ) external;

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Withdraw ETH to caller's account in L1.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of ETH to be withdrawn.
    /// @param gasLimit Optional, gas limit used to complete the withdraw on L1.
    function withdrawETH(
        address l2Token,
        string memory l1Token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable;

    /// @notice Withdraw ETH to caller's account in L1.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of ETH to be withdrawn.
    /// @param data Optional data to forward to recipient's account.
    /// @param gasLimit Optional, gas limit used to complete the withdraw on L1.
    function withdrawETHAndCall(
        address l2Token,
        string memory l1Token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external payable;
}
