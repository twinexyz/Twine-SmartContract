// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {L1ERC20Gateway} from "./L1ERC20Gateway.sol";
import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL1ERC20Gateway} from "./interfaces/IL1ERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";
import {TwineL1GatewayBase} from "../../libraries/gateway/TwineL1GatewayBase.sol";
import {ITwineL1MessengerBase} from "../../libraries/messenger/ITwineL1MessengerBase.sol";

/// @title L1CustomERC20Gateway
/// @notice The `L1CustomERC20Gateway` is used to deposit ERC20 compatible tokens on layer 1 and
/// finalize withdraw the tokens from layer 2
contract L1CustomERC20Gateway is L1ERC20Gateway {
    using TypeConversionLib for string;
    using TypeConversionLib for address;

    /// @notice Mapping from l1 token address to l2 token address for ERC20 token.
    mapping(address => address) public tokenMapping;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
     constructor(){
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1CustomERC20Gateway.
    /// @param _router The address of L1GatewayRouter in L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
    function initialize(
        address _router,
        address _messenger,
        address _roleManager
    ) external initializer {
        TwineL1GatewayBase._initialize(_router, _messenger, _roleManager);
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL1ERC20Gateway
    function getL2ERC20Address(
        address _l1Token
    ) external view override returns (address) {
        return tokenMapping[_l1Token];
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 1 to layer 2 token mapping.
    /// @param _l1Token The address of ERC20 token on layer 1.
    /// @param _l2Token The address of corresponding ERC20 token on layer 2.
    function updateTokenMapping(
        address _l1Token,
        address _l2Token
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_l1Token != address(0), "token address cannot be 0");
        require(_l2Token != address(0), "token address cannot be 0");

        address _oldL2Token = tokenMapping[_l1Token];
        tokenMapping[_l1Token] = _l2Token;

        emit UpdateTokenMapping(_l1Token, _oldL2Token, _l2Token);
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @inheritdoc L1ERC20Gateway
    function _beforeFinalizeWithdrawERC20(
        address _l1Token,
        address _l2Token
    ) internal virtual override {
        require(msg.value == 0, "nonzero msg.value");
        require(_l1Token != address(0), "token address cannot be 0");
        require(_l2Token != address(0), "token address cannot be 0");
        require(_l2Token == tokenMapping[_l1Token], "l2 token mismatch");
    }

    /// @inheritdoc L1ERC20Gateway
    function _deposit(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual override  {
        require(_amount > 0, "Amount can not be zero");
        require(msg.value > 0, "Amount for gas is needed");
        require(msg.value >= _gasLimit, "Not efficient gas value");
        address _l2Token = tokenMapping[_token];
        require(_l2Token != address(0), "no corresponding l2 token");

        // 1. Transfer token into this contract.
        address _from;
        (_from, _amount, _data) = _transferERC20In(_token, _amount, _data);

        // 4. Send message to L1TwineMessenger.
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineL1MessengerBase.TransactionType.deposit,
            _from,
            _to,
            _token,
            _l2Token,
           _amount
        );
    }

    function _forcedWithdrawalERC20(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual override nonReentrant {
        require(_amount > 0, "withdrawing zero amount not allowd");
        // Extract real sender if this call is from L1GatewayRouter
        address _from;
        (_from, _data) = _getRealSender(_data);
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineL1MessengerBase.TransactionType.withdrawal,
            _from,
            _to,
            _l1Token,
            _l2Token,
            _amount
        );

        emit forcedWithdrawalERC20Initated(
            _from,
            _to,
            _l1Token,
            _l2Token,
            _amount,
            block.number
        );
    }
}
