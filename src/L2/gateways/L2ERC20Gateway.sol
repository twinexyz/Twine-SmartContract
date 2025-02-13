// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL2ERC20Gateway} from "./interfaces/IL2ERC20Gateway.sol";
import {TwineL2GatewayBase} from "../../libraries/gateway/TwineL2GatewayBase.sol";

abstract contract L2ERC20Gateway is TwineL2GatewayBase, IL2ERC20Gateway {
    
    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20(
        address _l2token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit
    ) external payable override nonReentrant {
        _withdraw(_l2token, _to, _amount,_chainId,_gasLimit, new bytes(0));
    }

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20AndCall(
        address _l2Token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes calldata _data
    ) external payable override nonReentrant {
        _withdraw(_l2Token, _to, _amount,_chainId,_gasLimit, _data);
    }

    /**********************
     * Internal Functions *
     **********************/

    function _withdraw(
        address _token,
        string memory _to,
        uint256 _amount,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _data
    ) internal virtual;
}
