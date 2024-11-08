// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL2ETHGateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when someone withdraw ETH from L2 to L1.
    /// @param from The address of sender in L2.
    /// @param to The address of recipient in L1.
    /// @param amount The amount of ETH will be deposited from L2 to L1.
    event WithdrawETH(address indexed from, address indexed to, uint256 amount,uint256 chainId);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Withdraw ETH to caller's account in L1.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of ETH to be withdrawn.
    /// @param gasLimit Optional, gas limit used to complete the withdraw on L1.
    function withdrawETH(
        address to,
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
        address to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external payable;

}
