// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IL1ETHGateway} from "../../L1/gateways/IL1ETHGateway.sol";
import {IL2ETHGateway} from "./IL2ETHGateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";


/// @title L2ETHGateway
/// @notice The `L2ETHGateway` contract is used to withdraw ETH token on layer 2 and
/// finalize deposit ETH from layer 1.
/// @dev The ETH are not held in the gateway. The ETH will be sent to the `L2ScrollMessenger` contract.
/// On finalizing deposit, the Ether will be transferred from `L2ScrollMessenger`, then transfer to recipient.
contract L2ETHGateway is TwineGatewayBase,IL2ETHGateway {

     /***************
     * Constructor *
     ***************/
    constructor(
        address _counterpart,
        address _router,
        address _messenger
    ) TwineGatewayBase(_counterpart, _router, _messenger) {
        _disableInitializers();
    }

     /// @notice Initialize the storage of L2ETHGateway.
    ///
    /// @dev The parameters `_counterpart`, `_router` and `_messenger` are no longer used.
    ///
    /// @param _counterpart The address of L1ETHGateway in L1.
    /// @param _router The address of L2GatewayRouter in L2.
    /// @param _messenger The address of L2ScrollMessenger in L2.
    function initialize(
        address _counterpart,
        address _router,
        address _messenger
    ) external initializer {
        TwineGatewayBase._initialize(_counterpart, _router, _messenger);
    }
    

     /// @inheritdoc IL2ETHGateway
    function withdrawETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) public payable override {
        _withdraw(_to, _amount, new bytes(0), _gasLimit);
    }

    /// @inheritdoc IL2ETHGateway
    function finalizeDepositETH(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable override {
        require(msg.value == _amount, "msg.value mismatch");

        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _to.call{value: _amount}("");
        require(_success, "ETH transfer failed");

       _doCallback(_to, _data);

        emit FinalizeDepositETH(_from, _to, _amount, _data);
    }

    /// @dev The internal ETH withdraw implementation.
    /// @param _to The address of recipient's account on L1.
    /// @param _amount The amount of ETH to be withdrawn.
    /// @param _data Optional data to forward to recipient's account.
    /// @param _gasLimit Optional gas limit to complete the deposit on L1.
    function _withdraw(
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) internal virtual {
        require(msg.value > 0, "withdraw zero eth");

        address _from = msg.sender;

        bytes memory _message = abi.encodeCall(IL1ETHGateway.finalizeWithdrawETH, (_from, _to, _amount, _data));
        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(counterpart, _amount, _message, _gasLimit);

        emit WithdrawETH(_from, _to, _amount, _data);
    }
}