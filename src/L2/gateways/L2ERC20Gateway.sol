// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL2ERC20Gateway} from "./interfaces/IL2ERC20Gateway.sol";
import {TwineL2GatewayBase} from "../../libraries/gateway/TwineL2GatewayBase.sol";

abstract contract L2ERC20Gateway is TwineL2GatewayBase, IL2ERC20Gateway {
    
    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20(
        address l2token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable override nonReentrant {
        _withdraw(l2token, to, amount,chainId,gasLimit, new bytes(0));
    }

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20AndCall(
        address l2Token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes calldata data
    ) external payable override nonReentrant {
        _withdraw(l2Token, to, amount,chainId,gasLimit, data);
    }

    /**********************
     * Internal Functions *
     **********************/

    function _withdraw(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes memory data
    ) internal virtual;
}
