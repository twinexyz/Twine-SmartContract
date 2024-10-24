// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IXERC20} from "@xtoken/contracts/interfaces/IXERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IL1XERC20Gateway} from "../../L1/gateways/interfaces/IL1XERC20Gateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {IL2XERC20Gateway} from "./interfaces/IL2XERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";
import {IXERC20Lockbox} from "../../libraries/token/IXERC20Lockbox.sol";
import {ITwineMessenger} from "../../libraries/ITwineMessenger.sol";

contract L2XERC20Gateway is TwineGatewayBase,IL2XERC20Gateway {
     /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for XERC20 token is updated.
    /// @param l1Token The address of XERC20 token in layer 2.
    /// @param oldL2Token The address of the old corresponding XERC20 token in layer 1.
    /// @param newL2Token The address of the new corresponding XERC20 token in layer 1.
    event UpdateTokenMapping(address indexed l1Token, address indexed oldL2Token, address indexed newL2Token);

    /*************
     * Variables *
     *************/

    struct XTokenConfig {
        address l1Token;
        address l1xToken;
        address l2xToken;
        address l1LockBox;
        address l2LockBox;
    }

      /// @notice Mapping from l1 token address to l2 token address for XERC20 token.
    mapping(address => XTokenConfig) public tokenMapping;

    /***************
     * Constructor *
     ***************/

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1CustomERC20Gateway.
    ///
    /// @dev The parameters `_counterpart`, `_router` and `_messenger` are no longer used.
    ///
    /// @param _counterpart The address of L2CustomERC20Gateway in L2.
    /// @param _router The address of L1GatewayRouter in L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
    function initialize(
        address _counterpart,
        address _router,
        address _messenger
    ) external initializer {
        TwineGatewayBase._initialize(_counterpart, _router, _messenger);
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL2XERC20Gateway
    // function getL2XERC20Address(address _l1Token) public view override returns (address) {
    //     return tokenMapping[_l1Token];
    // }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 1 to layer 2 token mapping.
    /// @param _l1Token The address of ERC20 token on layer 1.

    function updateTokenMapping(address _l1Token,XTokenConfig memory xTokenConfig) external payable {
        XTokenConfig memory oldxTokenConfig = tokenMapping[xTokenConfig.l1Token];
        address _oldL1Token = oldxTokenConfig.l1Token;
        address l2Token = xTokenConfig.l1Token;
        tokenMapping[l2Token] = xTokenConfig;
        tokenMapping[l2Token].l1Token = _l1Token;

        emit UpdateTokenMapping(l2Token, _oldL1Token, _l1Token);
    }

     /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL2XERC20Gateway
    function withdrawXERC20(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _withdraw(_token, _to, _amount, new bytes(0), _gasLimit);
    }

    /// @inheritdoc IL2XERC20Gateway
    function withdrawXERC20AndCall(
        address _token,
        address _to,
        uint256 _amount,
        bytes calldata _data,
        uint256 _gasLimit
    ) external payable override {
        _withdraw(_token, _to, _amount, _data, _gasLimit);
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @dev Internal function to do all the deposit operations.
    function _withdraw(
        address _token,
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) internal {
        XTokenConfig memory xTokenInfo = tokenMapping[_token];
        address _l1Token = xTokenInfo.l1Token;
        require(_l1Token != address(0), "no corresponding l1 token");
        address _from = _msgSender();
        if (router == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }
        require(_amount > 0, "withdraw zero amount");

         if (_token != xTokenInfo.l2xToken) {
            bool isNative = IXERC20Lockbox(xTokenInfo.l2LockBox).IS_NATIVE();
            if (isNative) {
                 IXERC20Lockbox(xTokenInfo.l2LockBox).depositNative{value: _amount}();
            } else {
                SafeERC20.safeTransferFrom(IERC20(_token), _msgSender(), address(this), _amount);
                SafeERC20.safeIncreaseAllowance(IERC20(_token), xTokenInfo.l2LockBox, _amount);
                IXERC20Lockbox(xTokenInfo.l2LockBox).depositTo(address(this),_amount);
               
            }
        }else{
            SafeERC20.safeTransferFrom(IERC20(_token), _msgSender(), address(this), _amount);
        }
         IXERC20(xTokenInfo.l2xToken).burn(address(this), _amount);

        bytes memory _message = abi.encode(_l1Token,_token, _from, _to, _amount, _data);

        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineMessenger.TransactionType.withdrawal,
            counterpart,
            0,
            _message,
            _gasLimit,
            _from
        );
        emit WithdrawXERC20(_l1Token, _token, _from, _to, _amount, _data);

    }


}