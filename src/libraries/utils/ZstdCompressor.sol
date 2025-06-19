// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

interface IZstdPrecompile {
    function compress(bytes memory) external pure returns (bytes memory);
    function decompress(bytes memory) external pure returns (bytes memory);
}

abstract contract ZstdCompressor is ContextUpgradeable, ReentrancyGuardUpgradeable {
    address internal ZSTD_PRECOMPILE_ADDRESS;

    bytes4 private constant COMPRESS_SELECTOR = IZstdPrecompile.compress.selector;
    bytes4 private constant DECOMPRESS_SELECTOR = IZstdPrecompile.decompress.selector;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __ZstdCompressor__init(
        address _zstd
    ) internal onlyInitializing {
        ZSTD_PRECOMPILE_ADDRESS = _zstd;
    }


    function _compress(bytes memory data) internal returns (bytes memory ) {
        (bool success, bytes memory result) = ZSTD_PRECOMPILE_ADDRESS.call(
            abi.encodePacked(COMPRESS_SELECTOR, data)
        );
        require(success, "Call failed");
        return result;
    }

    function _decompress(bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory result) = ZSTD_PRECOMPILE_ADDRESS.call(
            abi.encodePacked(DECOMPRESS_SELECTOR, data)
        );
        require(success, "Call failed");
        return result;
    }
}