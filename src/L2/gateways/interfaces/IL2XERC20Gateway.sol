// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IL2XERC20Gateway {
    /**********
     * Events *
     **********/
     
    /// @notice Emitted when someone withdraw XERC20 token from L2 to L1.
    /// @param l1Token The address of the token in L1.
    /// @param l2Token The address of the token in L2.
    /// @param from The address of sender in L2.
    /// @param to The address of recipient in L1.
    /// @param amount The amount of token will be deposited from L2 to L1.
    /// @param data The optional calldata passed to recipient in L1.
    event WithdrawXERC20(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        string to,
        uint256 amount,
        uint256 chainId,
        bytes data
    );

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Return the corresponding l1 token address given l2 token address.
    /// @param l2Token The address of l2 token.
    // function getL1XERC20Address(address l2Token) external view returns (address);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Withdraw of some token to a recipient's account on L1.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param token The address of token in L2.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of token to transfer.
    /// @param gasLimit Unused, but included for potential forward compatibility considerations.
    function withdrawXERC20(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable;

    /// @notice Withdraw of some token to a recipient's account on L1 and call.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param token The address of token in L2.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of token to transfer.
    /// @param data Optional data to forward to recipient's account.
    /// @param gasLimit Unused, but included for potential forward compatibility considerations.
    function withdrawXERC20AndCall(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external payable;
}
