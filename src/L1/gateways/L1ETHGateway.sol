// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IL1ETHGateway} from "./IL1ETHGateway.sol";
import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL2ETHGateway} from "../../L2/gateways/IL2ETHGateway.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";


contract L1ETHGateway is TwineGatewayBase,IL1ETHGateway{

     /***************
     * Constructor *
     ***************/
    constructor(
        address _counterpart,
        address _router,
        address _messenger
    ) TwineGatewayBase(_counterpart, _router, _messenger){
        _disableInitializers();
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
        _deposit(_to, _amount, new bytes(0), _gasLimit);
    }

    function onDropMessage(bytes calldata _message) external payable virtual {
        // _message should start with 0x232e8748  =>  finalizeDepositETH(address,address,uint256,bytes)
        require(bytes4(_message[0:4]) == IL2ETHGateway.finalizeDepositETH.selector, "invalid selector");

        // decode (receiver, amount)
        (address _receiver, , uint256 _amount, ) = abi.decode(_message[4:], (address, address, uint256, bytes));

        require(_amount == msg.value, "msg.value mismatch");

        (bool _success, ) = _receiver.call{value: _amount}("");
        require(_success, "ETH transfer failed");

        emit RefundETH(_receiver, _amount);
    }


    /// @inheritdoc IL1ETHGateway
    function finalizeWithdrawETH(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable override {
        require(msg.value == _amount, "msg.value mismatch");

        // @note can possible trigger reentrant call to messenger,
        // but it seems not a big problem.
        (bool _success, ) = _to.call{value: _amount}("");
        require(_success, "ETH transfer failed");

        _doCallback(_to, _data);

        emit FinalizeWithdrawETH(_from, _to, _amount, _data);
    }

     /// @dev The internal ETH deposit implementation.
    /// @param _to The address of recipient's account on L2.
    /// @param _amount The amount of ETH to be deposited.
    /// @param _data Optional data to forward to recipient's account.
    /// @param _gasLimit Gas limit required to complete the deposit on L2.
    function _deposit(
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) internal virtual {
        require(_amount > 0, "deposit zero eth");

        // 1. Extract real sender if this call is from L1GatewayRouter.
        address _from = msg.sender;

        // @note no rate limit here, since ETH is limited in messenger

        // 2. Generate message passed to L1ScrollMessenger.
        bytes memory _message = abi.encodeCall(IL2ETHGateway.finalizeDepositETH, (_from, _to, _amount, _data));

        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(counterpart, _amount, _message, _gasLimit, _from);

        emit DepositETH(_from, _to, _amount, _data);
    }

}