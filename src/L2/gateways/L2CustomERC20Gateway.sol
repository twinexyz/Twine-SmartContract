// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL2ERC20Gateway, L2ERC20Gateway} from "./L2ERC20Gateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {IL1ERC20Gateway} from "../../L1/gateways/interfaces/IL1ERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineL2GatewayBase} from "../../libraries/gateway/TwineL2GatewayBase.sol";
import {ITwineERC20} from "../../libraries/token/ITwineERC20.sol";

/// @title L2CustomERC20Gateway
/// @notice The `L2CustomERC20Gateway` is used to withdraw custom ERC20 compatible tokens on layer 2 and
/// finalize deposit the tokens from layer 1.
/// @dev The withdrawn tokens will be burned directly. On finalizing deposit, the corresponding
/// tokens will be minted and transferred to the recipient.
contract L2CustomERC20Gateway is L2ERC20Gateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for ERC20 token is updated.
    /// @param l2Token The address of corresponding ERC20 token in layer 2.
    /// @param oldL1Token The address of the old corresponding ERC20 token in layer 1.
    /// @param newL1Token The address of the new corresponding ERC20 token in layer 1.
    event UpdateTokenMapping(uint256 indexed chainId,address indexed l2Token, address indexed oldL1Token, address newL1Token);

    /*************
     * Variables *
     *************/

    /// @notice Mapping from layer 2 token address to layer 1 token address for ERC20 token.
    /// chainId=>l2Token=>l1Token
    mapping(uint256=>mapping(address => address)) public tokenMapping;

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
    /// @param _counterpart The address of `L1CustomERC20Gateway` contract in L1.
    /// @param _router The address of `L2GatewayRouter` contract in L2.
    /// @param _messenger The address of `L2TwineMessenger` contract in L2.
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

    /// @inheritdoc IL2ERC20Gateway
    function getL1ERC20Address(uint256 _chainId,address _l2Token) external view override returns (address) {
        return tokenMapping[_chainId][_l2Token];
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 2 to layer 1 token mapping.
    ///
    /// @dev To make the token mapping consistent with L1, this should be called from L1.
    ///
    /// @param _l2Token The address of corresponding ERC20 token on layer 2.
    /// @param _l1Token The address of ERC20 token on layer 1.
    ///@param _chainId The chain Id of l1 Token.
    function updateTokenMapping(uint256 _chainId,address _l2Token, address _l1Token) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_l2Token != address(0) && _l1Token != address(0)," Token address cann't be zero");
        address _oldL1Token = tokenMapping[_chainId][_l2Token];
        tokenMapping[_chainId][_l2Token] = _l1Token;

        emit UpdateTokenMapping(_chainId,_l2Token, _oldL1Token, _l1Token);
    }
    /**********************
     * Internal Functions *
     **********************/

    /// @inheritdoc L2ERC20Gateway
    function _withdraw(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual override  {
        address _l1Token = tokenMapping[_chainId][_token];
        require(_l1Token != address(0), "no corresponding l1 token");
        
        require(_amount > 0, "Amout must be greater than zero");
        

        // 1. Extract real sender if this call is from L2GatewayRouter.
        address _from = _msgSender();
        if (router == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }

        // 2. Burn token.
        ITwineERC20(_token).burn(_from, _amount);

        // 3. Generate message passed to L1CustomERC20Gateway.
        bytes memory _message = abi.encodeCall(
            IL1ERC20Gateway.finalizeWithdrawERC20,(_l1Token,_token, _from, _to, _amount, _data));

        // 4. Send message to L2TwineMessenger.
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
}
