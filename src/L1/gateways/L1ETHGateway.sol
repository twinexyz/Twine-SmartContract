// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL1ETHGateway} from "./interfaces/IL1ETHGateway.sol";
import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL2ETHGateway} from "../../L2/gateways/interfaces/IL2ETHGateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";
import {ITwineMessenger} from "../../libraries/ITwineMessenger.sol";


contract L1ETHGateway is TwineGatewayBase, IL1ETHGateway {
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

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL1ETHGateway
    function depositETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _deposit(_to, _amount,_gasLimit,new bytes(0));
    }

    /// @inheritdoc IL1ETHGateway
    function depositETHAndCall(
        address _to,
        uint256 _amount,
        uint256 _gasLimit,
        bytes calldata _data
    ) external payable override {
        _deposit(_to, _amount, _gasLimit,_data);
    }

    /// @inheritdoc IL1ETHGateway
    function forcedWithdrawalETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _forcedWithdrawalEth(_to, _amount, _gasLimit);
    }

    /// @inheritdoc IL1ETHGateway
    function finalizeWithdrawETH(
        address _from,
        address _to,
        uint256 _amount
    ) external payable override onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN()) {
        require(msg.value == _amount, "msg.value mismatch");

        // @note can possible trigger reentrant call to messenger,
        // but it seems not a big problem.
        (bool _success, ) = _to.call{value: _amount}("");
        require(_success, "ETH transfer failed");

        emit FinalizeWithdrawETH(_from, _to,block.number, _amount);
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

        // 1. Extract real sender if this call is from L1GatewayRouter.
        address _from = _msgSender();
        if (router == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }

        // @note no rate limit here, since ETH is limited in messenger

        // 2. Generate message passed to L1TwineMessenger.
        bytes memory _message = abi.encode(_from, _to, _amount);

        // 3. Calculate the type of transaction
        ITwineMessenger.TransactionType _type = ITwineMessenger.TransactionType.deposit;

        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            _type,
            counterpart,
            _amount,
            _message,
            _gasLimit,
            _from
        );

        emit DepositETH(_from, _to, block.number, _amount);
    }

    /// @dev The internal ETH forced withdrawal implementation.
    /// @param _to The address of recipient's account in L1.
    /// @param _amount The amount of ETH to be withdrawn.
    /// @param _gasLimit Gas limit required to complete withdrawal.
    function _forcedWithdrawalEth(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) internal virtual {
        require(_amount > 0, "withdrawing zero amount not allowd");
        // 1. Extract real sender if this call is from L1GatewayRouter
        address _from = _msgSender();

        // 2. Generate message passed to L1TwineMessenger.
        bytes memory _message = abi.encode(_from, _to, _amount);

        // 3. Calculate the type of transaction
        ITwineMessenger.TransactionType _type = ITwineMessenger.TransactionType.withdrawal;

        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            _type, 
            counterpart, 
            _amount, 
            _message, 
            _gasLimit, 
            _from
        );

        emit ForcedWithdrawalEth(_from, _to,block.number, _amount);
    }

}
