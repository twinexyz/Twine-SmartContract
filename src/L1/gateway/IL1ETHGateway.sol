// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IL1ETHGateway {

    /// @notice Emitted when someone deposit ETH from L1 to L2.
    /// @param from The address of sender in L1.
    /// @param to The address of recipient in L2.
    /// @param amount The amount of ETH will be deposited from L1 to L2.
    /// @param data The optional calldata passed to recipient in L2.
    event DepositETH(address indexed from, address indexed to, uint256 amount, bytes data);

    /// @notice Emitted when some ETH is refunded.
    /// @param recipient The address of receiver in L1.
    /// @param amount The amount of ETH refunded to receiver.
    event RefundETH(address indexed recipient, uint256 amount);

    /*****************************
    * Public Mutating Functions *
    *****************************/

    /// @notice Deposit ETH to caller's account in L2.
    /// @param amount The amount of ETH to be deposited.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    function depositETH(uint256 amount, uint256 gasLimit) external payable;

    /// @notice Deposit ETH to some recipient's account in L2.
    /// @param to The address of recipient's account on L2.
    /// @param amount The amount of ETH to be deposited.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    function depositETH(
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable;


}
