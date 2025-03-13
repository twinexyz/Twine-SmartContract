// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL1ETHGateway {
    /// @notice Emitted when someone deposit ETH from L1 to L2.
    /// @param from The address of sender in L1.
    /// @param to The address of recipient in L2.
    /// @param amount The amount of ETH will be deposited from L1 to L2.
    event DepositETH(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 blockNumber
    );

    /// @notice Emitted when some ETH is refunded.
    /// @param recipient The address of receiver in L1.
    /// @param amount The amount of ETH refunded to receiver.
    event RefundETH(address indexed recipient, uint256 amount);

    ///@notice Emmitted when L2TokenAddress  is set
    ///@param l2TokenAddress The L2 address of the token
    event L2TokenSET(address l2TokenAddress);
    
    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Deposit ETH to some recipient's account in L2.
    /// @param to The address of recipient's account on L2.
    /// @param amount The amount of ETH to be deposited.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    function depositETH(
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable;

    /// @notice Deposit ETH to some recipient's account in L2 and call the target contract.
    /// @param to The address of recipient's account on L2.
    /// @param amount The amount of ETH to be deposited.
    /// @param data Optional data to forward to recipient's account.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    function depositETHAndCall(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes calldata data
    ) external payable;

    /// @notice Complete ETH withdraw from L2 to L1 and send fund to recipient's account in L1.
    /// @dev This function should only be called by Twinechain
    /// @param to The address of recipient in L1 to receive ETH.
    function finalizeTokenWithdrawal(
        string memory l1Token,
        string memory l2Token,
        string memory to,
        string memory amount
    ) external payable;

    /// @notice Withdraw ETH form the user account in L2
    /// @param  to The address of recipient's account on L1.
    /// @param amount The amount of ETH to be withdrawan.
    /// @param gasLimit Gas limit required to complete the withdrawal.
    function forcedWithdrawalETH(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable;
}
