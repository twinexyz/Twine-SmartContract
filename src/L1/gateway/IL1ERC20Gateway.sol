// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IL1ERC20Gateway {
    /**********
     * Events *
     **********/

     /// @notice Emitted when someone deposit ERC20 token from L1 to L2.
    /// @param l1Token The address of the token in L1.
    /// @param l2Token The address of the token in L2.
    /// @param from The address of sender in L1.
    /// @param to The address of recipient in L2.
    /// @param amount The amount of token will be deposited from L1 to L2.
    /// @param data The optional calldata passed to recipient in L2.
    event DepositERC20(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        bytes data
    );

    /// @notice Emitted when some ERC20 token is refunded.
    /// @param token The address of the token in L1.
    /// @param recipient The address of receiver in L1.
    /// @param amount The amount of token refunded to receiver.
    event RefundERC20(address indexed token, address indexed recipient, uint256 amount);

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Return the corresponding l2 token address given l1 token address.
    /// @param _l1Token The address of l1 token.
    function getL2ERC20Address(address _l1Token) external view returns (address);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Deposit some token to a caller's account on L2.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param _token The address of token in L1.
    /// @param _amount The amount of token to transfer.
    /// @param _gasLimit Gas limit required to complete the deposit on L2.
    function depositERC20(
        address _token,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable;

    /// @notice Deposit some token to a recipient's account on L2.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param _token The address of token in L1.
    /// @param _to The address of recipient's account on L2.
    /// @param _amount The amount of token to transfer.
    /// @param _gasLimit Gas limit required to complete the deposit on L2.
    function depositERC20(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable;

    /// @notice Deposit some token to a recipient's account on L2 and call.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param _token The address of token in L1.
    /// @param _to The address of recipient's account on L2.
    /// @param _amount The amount of token to transfer.
    /// @param _data Optional data to forward to recipient's account.
    /// @param _gasLimit Gas limit required to complete the deposit on L2.
    function depositERC20AndCall(
        address _token,
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) external payable;

}