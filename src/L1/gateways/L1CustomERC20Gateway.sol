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
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1CustomERC20Gateway.
    /// @param _gatewayrouter The address of L1GatewayRouter in L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
    /// @param _roleManager The address of Role manager contract.
    function initialize(
        address _gatewayrouter,
        address _messenger,
        address _roleManager,
        uint64 _chainId
    ) external initializer {
        TwineL1GatewayBase._initialize(
            _gatewayrouter,
            _messenger,
            _roleManager,
            _chainId
        );
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL1ERC20Gateway
    function getL2ERC20Address(
        address l1Token
    ) external view override returns (address) {
        return tokenMapping[l1Token];
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 1 to layer 2 token mapping.
    /// @param l1Token The address of ERC20 token on layer 1.
    /// @param l2Token The address of corresponding ERC20 token on layer 2.
    function updateTokenMapping(
        address l1Token,
        address l2Token
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (l1Token == address(0) || l2Token == address(0)) {
            revert ZeroAddress();
        }
        address oldL2Token = tokenMapping[l1Token];
        tokenMapping[l1Token] = l2Token;

        emit UpdateTokenMapping(l1Token, oldL2Token, l2Token);
    }

    /// @notice Removes a token mapping
    /// @param l1Token The address of ERC20 token on layer 1 whose mapping is to be deleted.
    function removeTokenMapping(
        address l1Token
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (l1Token == address(0)) {
            revert ZeroAddress();
        }

        address oldL2Token = tokenMapping[l1Token];
        if (oldL2Token == address(0)) {
            revert NoCorrespondingL2Token();
        }

        delete tokenMapping[l1Token];

        emit UpdateTokenMapping(l1Token, oldL2Token, address(0));
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @inheritdoc L1ERC20Gateway
    function _beforeFinalizeWithdrawERC20(
        address l1Token,
        address l2Token
    ) internal virtual override {
        if (msg.value != 0) revert NonZeroMsgValue();
        if (l1Token == address(0) || l2Token == address(0)) {
            revert ZeroAddress();
        }
        if (l2Token != tokenMapping[l1Token]) revert L2TokenMismatch();
    }

    /// @inheritdoc L1ERC20Gateway
    function _deposit(
        address token,
        address to,
        uint256 amount,
        uint256 /* gasLimit */,
        bytes memory data
    ) internal virtual override {
        if (amount == 0) revert ZeroAmount();
        address l2Token = tokenMapping[token];
        if (l2Token == address(0)) revert NoCorrespondingL2Token();

        //  Transfer token into this contract.
        address from;
        (from, amount, data) = _transferERC20In(token, amount, data);

        // Send message to L1TwineMessenger.
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineL1MessengerBase.TransactionType.deposit,
            from,
            to,
            token,
            l2Token,
            amount,
            data
        );
    }

    function _forcedWithdrawalERC20(
        address l1Token,
        address l2Token,
        address to,
        uint256 amount,
        uint256 /* gasLimit */,
        bytes memory data
    ) internal virtual override {
        if (amount == 0) revert ZeroAmount();
        // Extract real sender if this call is from L1GatewayRouter
        address from;
        (from, data) = _getRealSender(data);
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineL1MessengerBase.TransactionType.withdrawal,
            from,
            to,
            l1Token,
            l2Token,
            amount,
            data
        );

        emit ForcedWithdrawalERC20Initated(
            from,
            to,
            l1Token,
            l2Token,
            amount,
            block.number
        );
    }
}
