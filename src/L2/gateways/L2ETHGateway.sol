// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IL1ETHGateway} from "../../L1/gateways/IL1ETHGateway.sol";
import {IL2ETHGateway} from "./IL2ETHGateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";


/// @title L2ETHGateway
/// @notice The `L2ETHGateway` contract is used to withdraw ETH token on layer 2 and
/// finalize deposit ETH from layer 1.
/// @dev The ETH are not held in the gateway. The ETH will be sent to the `L2ScrollMessenger` contract.
/// On finalizing deposit, the Ether will be transferred from `L2ScrollMessenger`, then transfer to recipient.
contract L2ETHGateway is IL2ETHGateway {

    // Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();
    
    // The address of corresponding L1 Gateway contract.
    address public immutable counterpart;
    
    // The address of corresponding L2ScrollMessenger contract.
    address public immutable messenger;

     /***************
     * Constructor *
     ***************/
    constructor(
        address _counterpart,
        address _messenger
    ) {
        if(_counterpart == address(0) || _messenger == address(0)) {
            revert ErrorZeroAddress();
        }
        counterpart = _counterpart;
        messenger = _messenger;
    }
    

     /// @inheritdoc IL2ETHGateway
    function withdrawETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) public payable override {
        _withdraw(_to, _amount, _gasLimit);
    }

    /// @inheritdoc IL2ETHGateway
    function finalizeDepositETH(
        address _from,
        address _to,
        uint256 _amount
    ) external payable override {
        require(msg.value == _amount, "msg.value mismatch");

        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _to.call{value: _amount}("");
        require(_success, "ETH transfer failed");


        emit FinalizeDepositETH(_from, _to, _amount);
    }

    /// @dev The internal ETH withdraw implementation.
    /// @param _to The address of recipient's account on L1.
    /// @param _amount The amount of ETH to be withdrawn.
    /// @param _gasLimit Optional gas limit to complete the deposit on L1.
    function _withdraw(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) internal virtual {
        require(msg.value > 0, "withdraw zero eth");

        address _from = msg.sender;

        bytes memory _message = abi.encodeCall(IL1ETHGateway.finalizeWithdrawETH, (_from, _to, _amount));
        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(counterpart, _amount, _message, _gasLimit);

        emit WithdrawETH(_from, _to, _amount);
    }
}