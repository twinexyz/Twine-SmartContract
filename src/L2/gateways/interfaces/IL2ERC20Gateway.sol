// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IL2ERC20Gateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when ERC20 token is deposited from L1 to L2 and transfer to recipient.
    /// @param l1Token The address of the token in L1.
    /// @param l2Token The address of the token in L2.
    /// @param from The address of sender in L1.
    /// @param to The address of recipient in L2.
    /// @param amount The amount of token withdrawn from L1 to L2.
    /// @param data The optional calldata passed to recipient in L2.
    event FinalizeDepositERC20(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        bytes data
    );

    /// @notice Emitted when someone withdraw ERC20 token from L2 to L1.
    /// @param l1Token The address of the token in L1.
    /// @param l2Token The address of the token in L2.
    /// @param from The address of sender in L2.
    /// @param to The address of recipient in L1.
    /// @param amount The amount of token will be deposited from L2 to L1.
    /// @param data The optional calldata passed to recipient in L1.
    event WithdrawERC20(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        bytes data
    );

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Return the corresponding l1 token address given l2 token address.
    /// @param l2Token The address of l2 token.
    function getL1ERC20Address(address l2Token) external view returns (address);

    /// @notice Return the corresponding l2 token address given l1 token address.
    /// @param l1Token The address of l1 token.
    function getL2ERC20Address(address l1Token) external view returns (address);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Withdraw of some token to a recipient's account on L1.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param token The address of token in L2.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of token to transfer.
    /// @param gasLimit Unused, but included for potential forward compatibility considerations.
    function withdrawERC20(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable;

    /// @notice Withdraw of some token to a recipient's account on L1 and call.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param token The address of token in L2.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of token to transfer.
    /// @param data Optional data to forward to recipient's account.
    /// @param gasLimit Unused, but included for potential forward compatibility considerations.
    function withdrawERC20AndCall(
        address token,
        address to,
        uint256 amount,
        bytes calldata data,
        uint256 gasLimit
    ) external payable;
    
}
