// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {IL2ERC20Gateway, L2ERC20Gateway} from "./L2ERC20Gateway.sol";

import {ITwineERC20} from "../../libraries/token/ITwineERC20.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {IL1ERC20Gateway} from "../../L1/gateways/interfaces/IL1ERC20Gateway.sol";
import {TwineL2GatewayBase} from "../../libraries/gateway/TwineL2GatewayBase.sol";

/// @title L2CustomERC20Gateway
/// @notice The `L2CustomERC20Gateway` is used to withdraw custom ERC20 compatible tokens on layer 2 and
/// finalize deposit the tokens from layer 1.
/// @dev The withdrawn tokens will be burned directly. On finalizing deposit, the corresponding
/// tokens will be minted and transferred to the recipient.
contract L2CustomERC20Gateway is L2ERC20Gateway {
    
    /*************
     * Variables *
     *************/

    /// @notice Mapping from layer 2 token address to layer 1 token address for ERC20 token.
    /// chainId=>l2Token=>l1Token
    mapping(uint256 => mapping(address => string)) public tokenMapping;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of `L2CustomERC20Gateway`.
    ///
    /// @dev The parameters `_counterpart`, `_router` and `_messenger` are no longer used.
    ///
    /// @param _router The address of `L2GatewayRouter` contract in L2.
    /// @param _messenger The address of `L2TwineMessenger` contract in L2.
    function initialize(
        address _router,
        address _messenger,
        address _roleManager
    ) external initializer {
        TwineL2GatewayBase._initialize(_router, _messenger, _roleManager);
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL2ERC20Gateway
    function getL1ERC20Address(
        uint256 _chainId,
        address _l2Token
    ) external view override returns (string memory) {
        return tokenMapping[_chainId][_l2Token];
    }

    /************************
     * Restricted Functions *
     ************************/
     
    function updateTokenMapping(
        uint256 _chainId,
        address _l2Token,
        string memory _l1Token
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(bytes(_l1Token).length > 0, "L1 token address cannot be empty");
        string memory _oldL1Token = tokenMapping[_chainId][_l2Token];
        tokenMapping[_chainId][_l2Token] = _l1Token;
        emit TokenMappingUpdated(_chainId, _l2Token, _oldL1Token, _l1Token);
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @inheritdoc L2ERC20Gateway
    function _withdraw(
        address _l2Token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual override {
        string memory _l1Token = tokenMapping[_chainId][_l2Token];

        require(bytes(_l1Token).length != 0, "l1 token is not mapped");

        require(_amount > 0, "Amout must be greater than zero");

        // 1. Extract real sender if this call is from L2GatewayRouter.
        address _from = _msgSender();
        if (router == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }

        // 2. Burn token.
        ITwineERC20(_l2Token).burn(_from, _amount);
        uint256 value;

        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(
            _from,
            _l2Token,
            _to,
            _l1Token,
            _amount,
            value,
            _chainId,
            _gasLimit
        );
    }
}
