// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICentralizedERC20Gateway {
    /***********
     * Events  *
     ***********/
    /// @notice Emitted when someone deposit ERC20 token from Centralized Brige to Twine.
    /// @param l1Token The address of the token in L1.
    /// @param l2Token The address of the token in L2.
    /// @param from The address of sender in L1.
    /// @param to The address of recipient in L2.
    /// @param amount The amount of token that will be deposited from L1 to L2.
    /// @param data The optional calldata passed to recipient in L2.
    event DepositERC20(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        uint256 blockNumber,
        bytes data
    );

    /// @notice Emitted when token mapping for ERC20 token is updated.
    /// @param l1Token The address of ERC20 token in L1.
    /// @param oldL2Token The address of the old corresponding ERC20 token in L2.
    /// @param newL2Token The address of the new corresponding ERC20 token in L2.
    event UpdateTokenMapping(
        address indexed l1Token,
        address indexed oldL2Token,
        address indexed newL2Token
    );

    /// @notice Emitted when ERC20 token withdrawal is finalized
    /// @param l1Token The address of the token in L1.
    /// @param l2Token The address of the token in L2.
    /// @param to The address of recipient in L1.
    /// @param amount The amount of token withdrawn from L2 to L1.
    event FinalizeWithdrawERC20(
        string indexed l1Token,
        string indexed l2Token,
        string to,
        string amount,
        uint64 nonce,
        uint64 chainId,
        uint256 blockNumber
    );

    /*****************
     * Custom Errors *
     *****************/

    /// @notice Thrown when deposit amount is zero
    error ZeroDepositAmount();

    /// @notice Thrown when non-zero message value provided
    error NonZeroMsgValue();

    /// @notice Thrown when L2 token doesn't match
    error L2TokenMismatch();

    /// @notice Thrown when no corresponding L2 token exists
    error NoCorrespondingL2Token();


    /*************************
     * Public View Functions *
     *************************/
    /// @notice get address of corressponding L2 Token
    /// @param l1Token The address of the token in L1.
    function getL2ERC20Address(address l1Token) external view returns (address);

    /*****************************
     * Public Mutating Functions *
     *****************************/
    /// @notice Deposit some token to a recipient's account twine.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param token The address of token in L1.
    /// @param to The address of recipient's account on L2.
    /// @param amount The amount of token to transfer.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    function depositERC20(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable;

    /// @notice Deposit some token to a recipient's account on twine and call.
    /// @dev Make this function payable to send relayer fee in Ether.
    /// @param token The address of token in L1.
    /// @param to The address of recipient's account on L2.
    /// @param amount The amount of token to transfer.
    /// @param data Optional data to forward to recipient's account.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    function depositERC20AndCall(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable;

    /// @notice Complete ERC20 withdraw from L2 to L1 and send fund to recipient's account in L1.
    /// @param l1Token The address of corresponding L1 token.
    /// @param l2Token The address of corresponding L2 token.
    /// @param to The address of recipient in L1 to receive the token.
    /// @param amount The amount of the token to withdraw.
    function finalizeTokenWithdrawal(
        string memory l1Token,
        string memory l2Token,
        string memory to,
        string memory amount,
        uint64 nonce
    ) external payable;

}