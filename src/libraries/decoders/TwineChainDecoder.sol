// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;
import {ITwineChain} from "../../L1/rollup/ITwineChain.sol";

library TwineChainDecoder {
    /// @dev Decode the execution proofs of a batch
    /// @dev (32 + 32 + 8 + 8) is the message length of public values
    /// @dev the last 8 bytes can be ignored as it represents solana message count
    /// @return prevBatchHash    bytes32 previous batch hash
    /// @return batchHash        bytes32 current batch hash
    /// @return ethMsgCount      uint64  ethereum message count
    function decodeBatchValues(bytes calldata publicValues)
        internal
        pure
        returns (
            bytes32 prevBatchHash,
            bytes32 batchHash,
            uint64  ethMsgCount
        )
    {
        require(publicValues.length == 80, "invalid length");

        assembly {
            // blob is calldata: offset 0x20 skips the length word
            prevBatchHash := calldataload(publicValues.offset)      
            batchHash     := calldataload(add(publicValues.offset, 0x20)) 
            ethMsgCount   := shr(192, calldataload(add(publicValues.offset, 0x40))) 
        }
    }

    function decodeL2WithdrawValues(
        bytes memory publicValues
    ) internal pure returns (ITwineChain.L2WithdrawValues memory) {
        (
            uint64 batchNumber,
            uint64 nonce,
            bytes32 batchHash,
            string memory to,
            string memory l1Token,
            string memory l2Token,
            string memory amount
        ) = abi.decode(
                publicValues,
                (uint64, uint64, bytes32, string, string, string, string)
            );

        return
            ITwineChain.L2WithdrawValues({
                batchNumber: batchNumber,
                nonce: nonce,
                batchHash: batchHash,
                to: to,
                l1Token: l1Token,
                l2Token: l2Token,
                amount: amount
            });
    }
}