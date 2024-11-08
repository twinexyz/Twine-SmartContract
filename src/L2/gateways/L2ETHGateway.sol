// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL1ETHGateway} from "../../L1/gateways/interfaces/IL1ETHGateway.sol";
import {IL2ETHGateway} from "./interfaces/IL2ETHGateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";
import {ITwineMessenger} from "../../libraries/ITwineMessenger.sol";


/// @title L2ETHGateway
/// @notice The `L2ETHGateway` contract is used to withdraw ETH token on layer 2 and
/// finalize deposit ETH from layer 1.
/// @dev The ETH are not held in the gateway. The ETH will be sent to the `L2TwineMessenger` contract.
/// On finalizing deposit, the Ether will be transferred from `L2TwineMessenger`, then transfer to recipient.
contract L2ETHGateway is TwineGatewayBase, IL2ETHGateway {
    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L2ETHGateway.
    ///
    /// @dev The parameters `_counterpart`, `_router` and `_messenger` are no longer used.
    ///
    /// @param _counterpart The address of L1ETHGateway in L1.
    /// @param _router The address of L2GatewayRouter in L2.
    /// @param _messenger The address of L2TwineMessenger in L2.
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

    /// @inheritdoc IL2ETHGateway
    function withdrawETH(
        address _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit
    ) public payable override {
        _withdraw(_to, _amount,_chainId, _gasLimit,new bytes(0));
    }

    function withdrawETHAndCall(
        address _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) public payable {
        _withdraw(_to, _amount,_chainId, _gasLimit,_data);
    }

    /// @dev The internal ETH withdraw implementation.
    /// @param _to The address of recipient's account on L1.
    /// @param _amount The amount of ETH to be withdrawn.
    /// @param _gasLimit Optional gas limit to complete the deposit on L1.
    function _withdraw(
        address _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual {
        require(msg.value > 0 && _amount > 0, "Invalid input: msg.value and amount must be greater than zero");

        address _from = _msgSender();

        if (router == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }

        bytes memory _message = abi.encodeCall(
            IL1ETHGateway.finalizeWithdrawETH,
            (_from, _to, _amount)
        );
        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(
            ITwineMessenger.TransactionType.withdrawal,
            counterpart,
            _amount,
            _message,
            _gasLimit
        );

        emit WithdrawETH(_from, _to, _amount,_chainId);
    }
}
