// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/console.sol";

import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL1ETHGateway} from "./interfaces/IL1ETHGateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";
import {TwineL1GatewayBase} from "../../libraries/gateway/TwineL1GatewayBase.sol";
import {ITwineL1MessengerBase} from "../../libraries/messenger/ITwineL1MessengerBase.sol";

contract L1ETHGateway is TwineL1GatewayBase, IL1ETHGateway {
    using TypeConversionLib for string;
    using TypeConversionLib for address;

    address l2TokenAddress;

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

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL1ETHGateway
    function depositETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _deposit(_to, _amount, _gasLimit, new bytes(0));
    }

    /// @inheritdoc IL1ETHGateway
    function depositETHAndCall(
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes calldata _data
    ) external payable override {
        _deposit(_to, _amount, _gasLimit, _data);
    }

    /// @inheritdoc IL1ETHGateway
    function forcedWithdrawalETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _data
    ) external payable override {
        _forcedWithdrawalEth(_to, _amount, _gasLimit, _data);
    }

    /// @inheritdoc IL1ETHGateway
    function finalizeTokenWithdrawal(
        string memory _l1Token,
        string memory _l2Token,
        string memory _to,
        string memory _amount
    ) external payable override nonReentrant onlyRoles(IRoleManager(roleManager).TWINE_CHAIN()) {
        require(_amount.stringToUint() > 0, "Amout must be greater than zero");
        (bool _success, ) = _to.stringToAddress().call{
            value: _amount.stringToUint()
        }("");
        require(_success, "ETH transfer failed");

        emit FinalizeWithdrawETH(
            _l1Token,
            _l2Token,
            _to,
            _amount,
            block.number
        );
    }

    /// @notice Set the l2TokenAddress
    function setL2TokenAddress(
        address _l2TokenAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_l2TokenAddress != address(0),"value cann't be zero");
        l2TokenAddress = _l2TokenAddress;
        emit L2TokenSET(_l2TokenAddress);
    }

    /// @dev The internal ETH deposit implementation.
    /// @param _to The address of recipient's account on L2.
    /// @param _amount The amount of ETH to be deposited.
    /// @param _gasLimit Gas limit required to complete the deposit on L2.
    function _deposit(
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual {
        require(_amount > 0, "Amount can not be zero");
        require(
            _amount + _gasLimit <= msg.value,
            "Amount and gas limit should not be greater than msg.value"
        );

        // 1. Extract real sender if this call is from L1GatewayRouter.
        address _from = _msgSender();
        if (gatewayRouter == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }

        // 3. Calculate the type of transaction
        ITwineL1MessengerBase.TransactionType _type = ITwineL1MessengerBase
            .TransactionType
            .deposit;

        IL1TwineMessenger(messenger).sendMessage{value: _gasLimit}(
            _type,
            _from,
            _to,
            address(0),
            l2TokenAddress, 
            _amount
        );
    }

    /// @dev The internal ETH forced withdrawal implementation.
    /// @param _to The address of recipient's account in L1.
    /// @param _amount The amount of ETH to be withdrawn.
    /// @param _gasLimit Gas limit required to complete withdrawal.
    function _forcedWithdrawalEth(
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual {
        require(_amount > 0, "withdrawing zero amount not allowed");
        // 1. Extract real sender if this call is from L1GatewayRouter
        address _from = _msgSender();
        if (gatewayRouter == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }
        // 3. Calculate the type of transaction
        ITwineL1MessengerBase.TransactionType _type = ITwineL1MessengerBase
            .TransactionType
            .withdrawal;

        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            _type,
             _from,
            _to,
            address(0),
            l2TokenAddress,
            _amount
        );
    }
}
