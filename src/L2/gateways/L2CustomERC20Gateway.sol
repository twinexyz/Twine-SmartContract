// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {ITwineERC20} from "../../libraries/token/ITwineERC20.sol";
import {IL2ERC20Gateway, L2ERC20Gateway} from "./L2ERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
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
    /// @param router The address of `L2GatewayRouter` contract in L2.
    /// @param messenger The address of `L2TwineMessenger` contract in L2.
    function initialize(
        address router,
        address messenger,
        address roleManager
    ) external initializer {
        TwineL2GatewayBase._initialize(router, messenger, roleManager);
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL2ERC20Gateway
    function getL1ERC20Address(
        uint256 chainId,
        address l2Token
    ) external view override returns (string memory) {
        return tokenMapping[chainId][l2Token];
    }

    /************************
     * Restricted Functions *
     ************************/

    function updateTokenMapping(
        uint256 chainId,
        address l2Token,
        string memory l1Token
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(bytes(l1Token).length > 0, "L1 token address cannot be empty");
        string memory oldL1Token = tokenMapping[chainId][l2Token];
        tokenMapping[chainId][l2Token] = l1Token;
        emit TokenMappingUpdated(chainId, l2Token, oldL1Token, l1Token);
    }

    function removeTokenMapping(
        uint256 chainId,
        address l2Token
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        string memory oldL1Token = tokenMapping[chainId][l2Token];
        if (bytes(oldL1Token).length == 0) {
            revert("Mapping does not exits");
        } 

        delete tokenMapping[chainId][l2Token];
        emit TokenMappingUpdated(chainId, l2Token, oldL1Token, "");
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @inheritdoc L2ERC20Gateway
    function _withdraw(
        address l2Token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes memory data
    ) internal virtual override {
        string memory l1Token = tokenMapping[chainId][l2Token];

        require(bytes(l1Token).length != 0, "l1 token is not mapped");

        require(amount > 0, "Amout must be greater than zero");

        // 1. Extract real sender if this call is from L2GatewayRouter.
        address from = _msgSender();
        if (router == from) {
            (from, data) = abi.decode(data, (address, bytes));
        }

        // 2. Burn token.
        ITwineERC20(l2Token).burn(from, amount);
        uint256 value;

        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(
            from,
            l2Token,
            to,
            l1Token,
            amount,
            value,
            chainId,
            gasLimit
        );
        emit WithdrawalInitiated(
            from,
            l2Token,
            to,
            l1Token,
            amount,
            chainId,
            block.number
        );
    }
}
