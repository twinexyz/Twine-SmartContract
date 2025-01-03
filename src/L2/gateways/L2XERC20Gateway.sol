// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IXERC20} from "@xtoken/contracts/interfaces/IXERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IL1XERC20Gateway} from "../../L1/gateways/interfaces/IL1XERC20Gateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {IL2XERC20Gateway} from "./interfaces/IL2XERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineL2GatewayBase} from "../../libraries/gateway/TwineL2GatewayBase.sol";
import {IXERC20Lockbox} from "../../libraries/token/IXERC20Lockbox.sol";

contract L2XERC20Gateway is TwineL2GatewayBase,IL2XERC20Gateway {
     /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for XERC20 token is updated.
    /// @param l1Token The address of XERC20 token in layer 2.
    /// @param oldL2Token The address of the old corresponding XERC20 token in layer 1.
    /// @param newL2Token The address of the new corresponding XERC20 token in layer 1.
    event UpdateTokenMapping(uint256 indexed _chainId,address indexed l1Token, address indexed oldL2Token, address newL2Token);

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
    mapping(uint256=>mapping(address => XTokenConfig)) public tokenMapping;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1CustomERC20Gateway.
    /// @param _counterpart The address of L1XERC20Gateway in L1.
    /// @param _router The address of L1GatewayRouter in L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
    function initialize(
        address _counterpart,
        address _router,
        address _messenger,
        address _roleManager
    ) external initializer {
        TwineL2GatewayBase._initialize(_counterpart, _router, _messenger,_roleManager);
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

    function updateTokenMapping(uint256 _chainId,address _l1Token,XTokenConfig memory xTokenConfig) external payable onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        XTokenConfig memory oldxTokenConfig = tokenMapping[_chainId][xTokenConfig.l1Token];
        address _oldL1Token = oldxTokenConfig.l1Token;
        address l2Token = xTokenConfig.l1Token;
        tokenMapping[_chainId][l2Token] = xTokenConfig;
        tokenMapping[_chainId][l2Token].l1Token = _l1Token;

        emit UpdateTokenMapping(_chainId,l2Token, _oldL1Token, _l1Token);
    }

     /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL2XERC20Gateway
    function withdrawXERC20(
        address _token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit
    ) external payable override {
        _withdraw(_token, _to, _amount,_chainId,_gasLimit, new bytes(0));
    }

    /// @inheritdoc IL2XERC20Gateway
    function withdrawXERC20AndCall(
        address _token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes calldata _data
    ) external payable override {
        _withdraw(_token, _to, _amount,_chainId, _gasLimit,_data);
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @dev Internal function to do all the deposit operations.
    function _withdraw(
        address _token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) internal {
        XTokenConfig memory xTokenInfo = tokenMapping[_chainId][_token];
        address _l1Token = xTokenInfo.l1Token;
        require(_l1Token != address(0), "no corresponding l1 token");
        address _from = _msgSender();
        if (router == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }
        require(_amount > 0, "withdrawing zero amount not allowd");

         if (_token != xTokenInfo.l2xToken) {
            bool isNative = IXERC20Lockbox(xTokenInfo.l2LockBox).IS_NATIVE();
            if (isNative) {
                 IXERC20Lockbox(xTokenInfo.l2LockBox).depositNative{value: _amount}();
            } else {
                SafeERC20.safeTransferFrom(IERC20(_token), _from, address(this), _amount);
                SafeERC20.safeIncreaseAllowance(IERC20(_token), xTokenInfo.l2LockBox, _amount);
                IXERC20Lockbox(xTokenInfo.l2LockBox).depositTo(address(this),_amount);
               
            }
        }else{
            SafeERC20.safeTransferFrom(IERC20(_token), _from, address(this), _amount);
        }
         IXERC20(xTokenInfo.l2xToken).burn(address(this), _amount);

        bytes memory _message = abi.encodeCall(
            IL1XERC20Gateway.finalizeTokenWithdrawal,(_l1Token,_token, _from,  stringToAddress(_to), _amount, _data));

        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(
            _from,
            _to,
            counterpartGateWay[_chainId][_l1Token],
            _gasLimit,
            _chainId,
            _gasLimit,
            _message
        );

    }

    function stringToAddress(string memory _addressString) public pure returns (address) {
    bytes memory stringBytes = bytes(_addressString);
    require(stringBytes.length == 42 && stringBytes[0] == '0' && stringBytes[1] == 'x', "Invalid address format");
    
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


}