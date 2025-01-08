// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL1ERC20Gateway} from "./interfaces/IL1ERC20Gateway.sol";
import {IL1GatewayRouter} from "./interfaces/IL1GatewayRouter.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {IL2ERC20Gateway} from "../../L2/gateways/interfaces/IL2ERC20Gateway.sol";
import {TwineL1GatewayBase} from "../../libraries/gateway/TwineL1GatewayBase.sol";
import {ITwineL1MessengerBase} from "../../libraries/messenger/ITwineL1MessengerBase.sol";

/// @title L1ERC20Gateway
/// @notice The `L1ERC20Gateway` as a base contract for ERC20 gateways in L1.
/// It has implementation of common used functions for ERC20 gateways.
abstract contract L1ERC20Gateway is IL1ERC20Gateway, TwineL1GatewayBase {
    
    using SafeERC20 for IERC20;
    /// @inheritdoc IL1ERC20Gateway
    function depositERC20(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _deposit(_token, _to, _amount, _gasLimit,new bytes(0));
    }

    /// @inheritdoc IL1ERC20Gateway
    function depositERC20AndCall(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _data
    ) external payable override {
        _deposit(_token, _to, _amount,_gasLimit, _data);
    }

    /// @inheritdoc IL1ERC20Gateway
    function forcedWithdrawalERC20(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _forcedWithdrawalERC20(_l1Token,_l2Token,_to, _amount, _gasLimit);
    }

    /// @inheritdoc IL1ERC20Gateway
    function finalizeTokenWithdrawal(
        string memory _l1Token,
        address _l2Token,
        string memory _to,
        uint256 _amount
    ) external payable virtual override nonReentrant{
        _beforeFinalizeWithdrawERC20(stringToAddress(_l1Token), _l2Token);
        
        IERC20(stringToAddress(_l1Token)).safeTransfer(stringToAddress(_to), _amount);

        emit FinalizeWithdrawERC20(stringToAddress(_l1Token), _l2Token, stringToAddress(_to),_amount,block.number);
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @dev Internal function hook to perform checks and actions before finalizing the withdrawal.
    /// @param _l1Token The address of corresponding L1 token in L1.
    /// @param _l2Token The address of corresponding L2 token in L2.
    function _beforeFinalizeWithdrawERC20(
        address _l1Token,
        address _l2Token
    ) internal virtual;   

    /// @dev Internal function to transfer ERC20 token to this contract.
    /// @param _token The address of token to transfer.
    /// @param _amount The amount of token to transfer.
    /// @param _data The data passed by caller.
    function _transferERC20In(
        address _token,
        uint256 _amount,
        bytes memory _data
    )
        internal
        returns (
            address,
            uint256,
            bytes memory
        )
    {
        address _sender = _msgSender();
        address _from = _sender;
        if (gatewayRouter == _sender) {
            // Extract real sender if this call is from L1GatewayRouter.
            (_from, _data) = abi.decode(_data, (address, bytes));
            _amount = IL1GatewayRouter(_sender).requestERC20(_from, _token, _amount);
        } else {
            // common practice to handle fee on transfer token.
            uint256 _before = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            uint256 _after = IERC20(_token).balanceOf(address(this));
            // no unchecked here, since some weird token may return arbitrary balance.
            _amount = _after - _before;
        }
        // ignore weird fee on transfer token
        require(_amount > 0, "deposit zero amount");

        return (_from, _amount, _data);
    }

    function stringToAddress(
        string memory _addressString
    ) public pure returns (address) {
        bytes memory stringBytes = bytes(_addressString);
        require(
            stringBytes.length == 42 &&
                stringBytes[0] == "0" &&
                stringBytes[1] == "x",
            "Invalid address format"
        );

        uint160 result = 0;
        for (uint i = 2; i < 42; i++) {
            result *= 16;
            uint8 digit = uint8(stringBytes[i]);
            if (digit >= 48 && digit <= 57) {
                result += (digit - 48);
            } else if (digit >= 65 && digit <= 70) {
                result += (digit - 55);
            } else if (digit >= 97 && digit <= 102) {
                result += (digit - 87);
            } else {
                revert("Invalid character in address string");
            }
        }
        return address(result);
    }

    /// @dev Internal function to do all the deposit operations.
    ///
    /// @param _token The token to deposit.
    /// @param _to The recipient address to recieve the token in L2.
    /// @param _amount The amount of token to deposit.
    /// @param _data Optional data to forward to recipient's account.
    /// @param _gasLimit Gas limit required to complete the deposit on L2.
    function _deposit(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual;

    function _forcedWithdrawalERC20(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) internal virtual;
}
