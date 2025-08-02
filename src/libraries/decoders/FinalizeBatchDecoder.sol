// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

library FinalizeBatchDecoder {
    /// @dev Decode the execution proofs of a batch
    /// @return prevBatchHash    bytes32 previous batch hash
    /// @return batchHash        bytes32 current batch hash
    /// @return ethMsgCount      uint64  ethereum message count
    function decodePacked(bytes calldata blob)
        internal
        pure
        returns (
            bytes32 prevBatchHash,
            bytes32 batchHash,
            uint64  ethMsgCount
        )
    {
        require(blob.length == 96, "invalid length");

        assembly {
            // blob is calldata: offset 0x20 skips the length word
            prevBatchHash := calldataload(blob.offset)           // bytes  0–31
            batchHash     := calldataload(add(blob.offset, 0x20)) // bytes 32–63
            ethMsgCount   := shr(192, calldataload(add(blob.offset, 0x40))) // bytes 64–71, big-endian
        }
    }
}