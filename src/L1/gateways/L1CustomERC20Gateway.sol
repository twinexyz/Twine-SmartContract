// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL1ERC20Gateway} from "./interfaces/IL1ERC20Gateway.sol";
import {L1ERC20Gateway} from "./L1ERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";
import {IL2ERC20Gateway} from "../../L2/gateways/interfaces/IL2ERC20Gateway.sol";

/// @title L1CustomERC20Gateway
/// @notice The `L1CustomERC20Gateway` is used to deposit ERC20 compatible tokens on layer 1 and
/// finalize withdraw the tokens from layer 2
contract L1CustomERC20Gateway is L1ERC20Gateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for ERC20 token is updated.
    /// @param l1Token The address of ERC20 token in layer 1.
    /// @param oldL2Token The address of the old corresponding ERC20 token in layer 2.
    /// @param newL2Token The address of the new corresponding ERC20 token in layer 2.
    event UpdateTokenMapping(
        address indexed l1Token,
        address indexed oldL2Token,
        address indexed newL2Token
    );

    /*************
     * Variables *
     *************/

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

    /// @inheritdoc IL1ERC20Gateway
    function getL2ERC20Address(address _l1Token)
        public
        view
        override
        returns (address)
    {
        return tokenMapping[_l1Token];
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 1 to layer 2 token mapping.
    /// @param _l1Token The address of ERC20 token on layer 1.
    /// @param _l2Token The address of corresponding ERC20 token on layer 2.
    function updateTokenMapping(address _l1Token, address _l2Token)
        external
        payable
        onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN())
    {
        require(_l2Token != address(0), "token address cannot be 0");

        address _oldL2Token = tokenMapping[_l1Token];
        tokenMapping[_l1Token] = _l2Token;

        emit UpdateTokenMapping(_l1Token, _oldL2Token, _l2Token);

        // update corresponding mapping in L2, 1000000 gas limit should be enough
        bytes memory _message = abi.encodeCall(
            L1CustomERC20Gateway.updateTokenMapping,
            (_l2Token, _l1Token)
        );
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            counterpart,
            0,
            _message,
            1000000,
            _msgSender()
        );
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @inheritdoc L1ERC20Gateway
    function _beforeFinalizeWithdrawERC20(
        address _l1Token,
        address _l2Token,
        address,
        address,
        uint256,
        bytes calldata
    ) internal virtual override {
        require(msg.value == 0, "nonzero msg.value");
        require(_l2Token != address(0), "token address cannot be 0");
        require(_l2Token == tokenMapping[_l1Token], "l2 token mismatch");
    }

    /// @inheritdoc L1ERC20Gateway
    function _beforeDropMessage(
        address,
        address,
        uint256
    ) internal virtual override {
        require(msg.value == 0, "nonzero msg.value");
    }

    /// @inheritdoc L1ERC20Gateway
    function _deposit(
        address _token,
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) internal virtual override nonReentrant {
        address _l2Token = tokenMapping[_token];
        require(_l2Token != address(0), "no corresponding l2 token");

        // 1. Transfer token into this contract.
        address _from;
        (_from, _amount, _data) = _transferERC20In(_token, _amount, _data);

        // 2. Generate message passed to L2CustomERC20Gateway.
        bytes memory _message = abi.encodeCall(
            IL2ERC20Gateway.finalizeDepositERC20,
            (_token, _l2Token, _from, _to, _amount, _data)
        );

        // 3. Send message to L1TwineMessenger.
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            counterpart,
            0,
            _message,
            _gasLimit,
            _from
        );

        emit DepositERC20(_token, _l2Token, _from, _to, _amount, _data);
    }
}
