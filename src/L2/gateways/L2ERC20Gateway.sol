// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL2ERC20Gateway} from "./interfaces/IL2ERC20Gateway.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";

abstract contract L2ERC20Gateway is TwineGatewayBase, IL2ERC20Gateway {
    /*************
     * Variables *
     *************/

    /// @dev The storage slots for future usage.
    uint256[50] private __gap;

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL2ERC20Gateway

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit
    ) external payable override {
        _withdraw(_token, _to, _amount,_chainId,_gasLimit, new bytes(0));
    }

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20AndCall(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes calldata _data
    ) external payable override {
        _withdraw(_token, _to, _amount,_chainId,_gasLimit, _data);
    }

    /**********************
     * Internal Functions *
     **********************/

    function _withdraw(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual;
}
