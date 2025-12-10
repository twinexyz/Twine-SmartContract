// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IL1ERC20Gateway} from "./interfaces/IL1ERC20Gateway.sol";
import {IL1GatewayRouter} from "./interfaces/IL1GatewayRouter.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";
import {TwineL1GatewayBase} from "../../libraries/gateway/TwineL1GatewayBase.sol";

/// @title L1ERC20Gateway
/// @notice The `L1ERC20Gateway` as a base contract for ERC20 gateways in L1.
/// It has implementation of common used functions for ERC20 gateways.
abstract contract L1ERC20Gateway is IL1ERC20Gateway, TwineL1GatewayBase {
    using SafeERC20 for IERC20;
    using TypeConversionLib for string;
    using TypeConversionLib for address;

    /// @inheritdoc IL1ERC20Gateway
    function depositERC20(
        address l1Token,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable override {
        if (msg.value < gasLimit) revert InsufficientGasValue();
        _deposit(l1Token, to, amount, gasLimit, new bytes(0));
    }

    /// @inheritdoc IL1ERC20Gateway
    function depositERC20AndCall(
        address l1Token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable override {
        _deposit(l1Token, to, amount, gasLimit, data);
    }

    /// @inheritdoc IL1ERC20Gateway
    function forcedWithdrawalERC20(
        address l1Token,
        address l2Token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable override nonReentrant {
        _forcedWithdrawalERC20(l1Token, l2Token, to, amount, gasLimit, data);
    }

    /// @inheritdoc IL1ERC20Gateway
    function finalizeTokenWithdrawal(
        string memory l1Token,
        string memory l2Token,
        string memory to,
        string memory amount,
        uint64 nonce
    )
        external
        payable
        virtual
        override
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_CHAIN())
    {
         if (amount.stringToUint() == 0) revert ZeroAmount();
        _beforeFinalizeWithdrawERC20(
            l1Token.stringToAddress(),
            l2Token.stringToAddress()
        );
        IERC20(l1Token.stringToAddress()).safeTransfer(
            to.stringToAddress(),
            amount.stringToUint()
        );
        emit FinalizeWithdrawERC20(
            l1Token,
            l2Token,
            to,
            amount,
            nonce,
            chainId,
            block.number
        );
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @dev Internal function hook to perform checks and actions before finalizing the withdrawal.
    /// @param l1Token The address of corresponding L1 token in L1.
    /// @param l2Token The address of corresponding L2 token in L2.
    function _beforeFinalizeWithdrawERC20(
        address l1Token,
        address l2Token
    ) internal virtual;

    /// @dev Internal function to transfer ERC20 token to this contract.
    /// @param token The address of token to transfer.
    /// @param amount The amount of token to transfer.
    /// @param data The data passed by caller.
    function _transferERC20In(
        address token,
        uint256 amount,
        bytes memory data
    ) internal nonReentrant returns (address, uint256, bytes memory) {
        address sender = _msgSender();
        address from = sender;
        if (gatewayRouter == sender) {
            // Extract real sender if this call is from L1GatewayRouter.
            (from, data) = abi.decode(data, (address, bytes));
            amount = IL1GatewayRouter(sender).requestERC20(from, token, amount);
        } else {
            // common practice to handle fee on transfer token.
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(from, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            // no unchecked here, since some weird token may return arbitrary balance.
            amount = balanceAfter - balanceBefore;
        }
        if (amount == 0) revert ZeroDepositAmount();
        return (from, amount, data);
    }

    /// @dev Internal function to get the real sender.
    /// @param data The data passed by caller.
    function _getRealSender(
        bytes memory data
    ) internal view returns (address, bytes memory) {
        address sender = _msgSender();
        address from = sender;
        if (gatewayRouter == sender) {
            // Extract real sender if this call is from L1GatewayRouter.
            (from, data) = abi.decode(data, (address, bytes));
        }
        return (from, data);
    }

    /// @dev Internal function to do all the deposit operations.
    ///
    /// @param token The token to deposit.
    /// @param to The recipient address to recieve the token in L2.
    /// @param amount The amount of token to deposit.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    /// @param data Optional data to forward to recipient's account.
    function _deposit(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) internal virtual;

    function _forcedWithdrawalERC20(
        address l1Token,
        address l2Token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) internal virtual;
}
