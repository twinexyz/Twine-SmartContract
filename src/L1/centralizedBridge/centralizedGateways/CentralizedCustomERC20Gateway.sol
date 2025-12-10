// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CentralizedERC20Gateway} from "./CentralizedERC20Gateway.sol";
import {ICentralizedTwineMessenger} from "../ICentralizedTwineMessenger.sol";
import {ICentralizedERC20Gateway} from "./interfaces/ICentralizedERC20Gateway.sol";
import {IRoleManager} from "../../../libraries/access/IRoleManager.sol";
import {TypeConversionLib} from "../../../libraries/utils/TypeConversionLib.sol";
import {TwineL1GatewayBase} from "../../../libraries/gateway/TwineL1GatewayBase.sol";
import {ITwineL1MessengerBase} from "../../../libraries/messenger/ITwineL1MessengerBase.sol";

/// @title CentralizedCustomERC20Gateway
/// @notice The `CentralizedERC20Gateway` is used to deposit ERC20 compatible tokens on centralized bridge and
/// finalize withdraw the tokens from twine
contract CentralizedCustomERC20Gateway is CentralizedERC20Gateway {
    using TypeConversionLib for string;
    using TypeConversionLib for address;

    /// @notice Mapping from centralized bridge token address to Twine token address for ERC20 token.
    mapping(address => address) public tokenMapping;

    
    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of CentralizedCustomERC20Gateway.
    /// @param _gatewayrouter The address of CentralizedGatewayRouter.
    /// @param _messenger The address of CentralizedTwineMessenger.
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
    /// @inheritdoc ICentralizedERC20Gateway
    function getL2ERC20Address(
        address l1Token
    ) external view override returns (address) {
        return tokenMapping[l1Token];
    }

       /************************
     * Restricted Functions *
     ************************/

    /// @notice Update centralize bridge to twine token mapping.
    /// @param l1Token The address of ERC20 token on this bridge.
    /// @param l2Token The address of corresponding ERC20 token on twine.
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
    /// @param l1Token The address of ERC20 token on this bridge whose mapping is to be deleted.
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

    /// @inheritdoc CentralizedERC20Gateway
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

    /// @inheritdoc CentralizedERC20Gateway
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
        ICentralizedTwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineL1MessengerBase.TransactionType.deposit,
            from,
            to,
            token,
            l2Token,
            amount,
            data
        );
    }
} 

