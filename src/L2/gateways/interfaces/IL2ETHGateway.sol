// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL2ETHGateway {

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Withdraw ETH to caller's account in L1.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of ETH to be withdrawn.
    /// @param gasLimit Optional, gas limit used to complete the withdraw on L1.
    function withdrawETH(
        address _l1Token,
        address _l2Token,
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
        address _l1Token,
        address _l2Token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external payable;

}
