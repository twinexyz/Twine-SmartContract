// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IL2ERC20Gateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for ERC20 token is updated.
    /// @param l2Token The address of corresponding ERC20 token in Twine.
    /// @param oldL1Token The address of the old corresponding ERC20 token in layer 1.
    /// @param newL1Token The address of the new corresponding ERC20 token in layer 1.
    event TokenMappingUpdated(
        uint256 indexed chainId,
        address indexed l2Token,
        string indexed oldL1Token,
        string newL1Token
    );

    /**
     * @notice Emitted when a withdrawal is initiated.
     * @dev This event is logged after burning tokens on L2 and before sending a message to L1.
     * @param from The address initiating the withdrawal.
     * @param l2Token The address of the token on Twine.
     * @param to The recipient's identifier on Layer 1, represented as a string.
     * @param l1Token The corresponding token address on Layer 1, stored as a string.
     * @param amount The amount of tokens withdrawn.
     * @param chainId The identifier of the L1 chain.
     */

    event WithdrawalInitiated(
        address indexed from,
        address indexed l2Token,
        string to,
        string l1Token,
        uint256 amount,
        uint256 chainId,
        uint256 blockNumber
    );

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Return the corresponding l1 token address given l2 token address.
    ///@param chainId id of the blockchain
    /// @param l2Token The address of l2 token.
    function getL1ERC20Address(
        uint256 chainId,
        address l2Token
    ) external view returns (string memory);

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

    /// @notice Withdraw of some token to a recipient's account on L1.
    /// @dev Make this function payable to send relayer fee
    /// @param token The address of token in L2.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of token to transfer.
    /// @param gasLimit Unused, but included for potential forward compatibility considerations.
    function withdrawERC20(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable;

    /// @notice Withdraw of some token to a recipient's account on L1 and call.
    /// @dev Make this function payable to send relayer fee
    /// @param token The address of token in L2.
    /// @param to The address of recipient's account on L1.
    /// @param amount The amount of token to transfer.
    /// @param data optional data to forward to recipient's account.
    /// @param gasLimit Unused, but included for potential forward compatibility considerations.
    function withdrawERC20AndCall(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external payable;
}
