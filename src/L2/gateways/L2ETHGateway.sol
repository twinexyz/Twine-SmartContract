// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL1ETHGateway} from "../../L1/gateways/interfaces/IL1ETHGateway.sol";
import {IL2ETHGateway} from "./interfaces/IL2ETHGateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {TwineL2GatewayBase} from "../../libraries/gateway/TwineL2GatewayBase.sol";


/// @title L2ETHGateway
/// @notice The `L2ETHGateway` contract is used to withdraw ETH token on layer 2 and
/// finalize deposit ETH from layer 1.
/// @dev The ETH are not held in the gateway. The ETH will be sent to the `L2TwineMessenger` contract.
/// On finalizing deposit, the Ether will be transferred from `L2TwineMessenger`, then transfer to recipient.
contract L2ETHGateway is TwineL2GatewayBase, IL2ETHGateway {
    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L2ETHGateway.
    /// @param _counterpart The address of L1ETHGateway in L1.
    /// @param _router The address of L2GatewayRouter in L2.
    /// @param _messenger The address of L2TwineMessenger in L2.
    function initialize(
        address _counterpart,
        address _router,
        address _messenger,
        address _roleManager
    ) external initializer {
        TwineL2GatewayBase._initialize(_counterpart, _router, _messenger,_roleManager);
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL2ETHGateway
    function withdrawETH(
        address _l1Token,
        address _l2Token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit
    ) external payable override nonReentrant {
        _withdraw(_l1Token,_l2Token,_to, _amount,_chainId, _gasLimit,new bytes(0));
    }

    /// @inheritdoc IL2ETHGateway
    function withdrawETHAndCall(
        address _l1Token,
        address _l2Token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) external payable override nonReentrant{
        _withdraw(_l1Token,_l2Token,_to, _amount,_chainId, _gasLimit,_data);
    }

    /// @dev The internal ETH withdraw implementation.
    /// @param _to The address of recipient's account on L1.
    /// @param _amount The amount of ETH to be withdrawn.
    /// @param _gasLimit Optional gas limit to complete the deposit on L1.
    function _withdraw(
        address _l1Token,
        address _l2Token,
        string memory _to,
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
            IL1ETHGateway.finalizeTokenWithdrawal,
            (_l1Token,_l2Token,stringToAddress(_to), _amount)
        );
        
        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(
            _from,
            _to,
            counterpartGateWay[_chainId][address(0)],
            _amount+_gasLimit,
            _chainId,
            _gasLimit,
            _message
        );
    }

    function stringToAddress(string memory _addressString) public pure returns (address) {
    bytes memory stringBytes = bytes(_addressString);
    require(stringBytes.length == 42 && stringBytes[0] == '0' && stringBytes[1] == 'x', "Invalid address format");
    
    uint160 result = 0;
    for (uint i = 2; i < 42; i++) {
        result *= 16;
        uint8 digit = uint8(stringBytes[i]);
        if (digit >= 48 && digit <= 57) {
            result += (digit - 48);
        } else if (digit >= 65 && digit <= 70) {
            result += (digit - 55);
        } else if (digit >= 97 && digit <= 102) {
            result += (digit - 87);
        } else {
            revert("Invalid character in address string");
        }
    }
    return address(result);
}
}
