// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {L1ERC20Gateway} from "./L1ERC20Gateway.sol";
import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL1ERC20Gateway} from "./interfaces/IL1ERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {IL2ERC20Gateway} from "../../L2/gateways/interfaces/IL2ERC20Gateway.sol";
import {TwineL1GatewayBase} from "../../libraries/gateway/TwineL1GatewayBase.sol";
import {ITwineL1MessengerBase} from "../../libraries/messenger/ITwineL1MessengerBase.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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
    ) public view override returns (address) {
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
    ) internal virtual override nonReentrant {
        require(_amount > 0, "Amount can not be zero");
        address _l2Token = tokenMapping[_token];
        require(_l2Token != address(0), "no corresponding l2 token");

        // 1. Transfer token into this contract.
        address _from;
        (_from, _amount, _data) = _transferERC20In(_token, _amount, _data);

        // 2. Generate message passed to L2CustomERC20Gateway.
        bytes memory _message = abi.encode(
            _token,
            _l2Token,
            _from,
            _to,
            _amount
        );

        // 4. Send message to L1TwineMessenger.
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineL1MessengerBase.TransactionType.deposit,
            addressToString(_to),
            addressToString(_token),
            addressToString(_l2Token),
            Strings.toString(_amount)
        );
    }

    function _forcedWithdrawalERC20(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) internal virtual override nonReentrant {
        require(_amount > 0, "withdrawing zero amount not allowd");
        // 1. Extract real sender if this call is from L1GatewayRouter
        address _from = _msgSender();

        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineL1MessengerBase.TransactionType.withdrawal,
            addressToString(_to),
            addressToString(_l1Token),
            addressToString(_l2Token),
            Strings.toString(_amount)
        );
    }

    function addressToString(
        address _address
    ) public pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
    
}
