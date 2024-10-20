// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IL2ETHGateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when someone withdraw ETH from L2 to L1.
    /// @param from The address of sender in L2.
    /// @param to The address of recipient in L1.
    /// @param amount The amount of ETH will be deposited from L2 to L1.
    event WithdrawETH(address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when ETH is deposited from L1 to L2 and transfer to recipient.
    /// @param from The address of sender in L1.
    /// @param to The address of recipient in L2.
    /// @param amount The amount of ETH deposited from L1 to L2.
    event FinalizeDepositETH(address indexed from, address indexed to, uint256 amount);

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
        uint256 gasLimit
    ) external payable;

    /// @notice Complete ETH deposit from L1 to L2 and send fund to recipient's account in L2.
    /// @dev This function should only be called by L2ScrollMessenger.
    ///      This function should also only be called by L1GatewayRouter in L1.
    /// @param _from The address of account who deposit ETH in L1.
    /// @param _to The address of recipient in L2 to receive ETH.
    /// @param _amount The amount of ETH to deposit.
    function finalizeDepositETH(
        address _from,
        address _to,
        uint256 _amount
    ) external payable;

}
