// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IL2ERC20Gateway} from "./interfaces/IL2ERC20Gateway.sol";
import {ITwineERC20} from "../../libraries/token/ITwineERC20.sol";
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
        _withdraw(l2token, to, amount, chainId, gasLimit, new bytes(0));
    }
    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20InEvm(
        address l2token,
        address to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable override nonReentrant {
        _withdraw(
            l2token,
            addressToString(to),
            amount,
            chainId,
            gasLimit,
            new bytes(0)
        );
    }
    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20InSvm(
        address l2token,
        string calldata to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable override nonReentrant {
        require(isValidSolanaAddressFormat(to), "Invalid Solana pubkey format");
        _withdraw(l2token, to, amount, chainId, gasLimit, new bytes(0));
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
        _withdraw(l2Token, to, amount, chainId, gasLimit, data);
    }

    /// @inheritdoc IL2ERC20Gateway
    function mintTokens(
        uint256 amount,
        address token,
        address receiver
    ) external payable override nonReentrant {
        require(amount > 0, "Amount can not be zero");
        ITwineERC20(token).mint(receiver, amount);
    }

    /// @inheritdoc IL2ERC20Gateway
    function burnTokens(
        uint256 amount,
        address token,
        address from
    ) external payable override nonReentrant {
        require(amount > 0, "Amount can not be zero");
        ITwineERC20(token).burn(from, amount);
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

    function isValidSolanaAddressFormat(
        string memory solanaPubkey
    ) internal pure returns (bool) {
        bytes memory addressBytes = bytes(solanaPubkey);
        // Check length is within valid range (32-44 characters)
        if (addressBytes.length < 32 || addressBytes.length > 44) {
            return false;
        }
        // Validate each character is in the base58 character set
        for (uint i = 0; i < addressBytes.length; i++) {
            bytes1 char = addressBytes[i];
            // Check if character is in valid base58 charset
            // Base58 uses: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
            if (
                !((char >= 0x31 && char <= 0x39) || // 1-9
                    (char >= 0x41 && char <= 0x48) || // A-H
                    (char >= 0x4A && char <= 0x4E) || // J-N
                    (char >= 0x50 && char <= 0x5A) || // P-Z
                    (char >= 0x61 && char <= 0x6B) || // a-k
                    (char >= 0x6D && char <= 0x7A)) // m-z
            ) {
                return false;
            }
        }
        return true;
    }

    /// @notice Converts an Ethereum address to its string representation
    ///  @param _address The Ethereum address to convert
    function addressToString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}
