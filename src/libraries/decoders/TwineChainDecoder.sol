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
    function decodeBatchValues(
        bytes calldata publicValues
    )
        internal
        pure
        returns (bytes32 prevBatchHash, bytes32 batchHash, uint64 ethMsgCount)
    {
        require(publicValues.length == 80, "invalid length");

        assembly {
            // blob is calldata: offset 0x20 skips the length word
            prevBatchHash := calldataload(publicValues.offset)
            batchHash := calldataload(add(publicValues.offset, 0x20))
            ethMsgCount := shr(
                192,
                calldataload(add(publicValues.offset, 0x40))
            )
        }
    }

    /// @dev Decode public values for l2 withdrawals zk proof
    /// @notice It expects address to have `0x` prefix
    function decodeL2WithdrawValues(
        bytes calldata publicValues
    )
        internal
        pure
        returns (ITwineChain.L2WithdrawValues memory withdrawValues)
    {
        require(publicValues.length >= 174, "data too short");
        withdrawValues.batchNumber = uint64(bytes8(publicValues[0:8]));
        withdrawValues.nonce = uint64(bytes8(publicValues[8:16]));
        withdrawValues.batchHash = bytes32(publicValues[16:48]);
        withdrawValues.to = string(publicValues[48:90]);
        withdrawValues.l1Token = string(publicValues[90:132]);
        withdrawValues.l2Token = string(publicValues[132:174]);
        withdrawValues.amount = string(publicValues[174:]);
    }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(data.length >= start + length, "Invalid slice range");

        bytes memory result = new bytes(length);

        assembly {
            // Get the pointer to the result's data
            let resultPtr := add(result, 0x20)
            // Get the pointer to the start position in the input data
            let dataPtr := add(add(data, 0x20), start)

            // Copy the data
            for {
                let i := 0
            } lt(i, length) {
                i := add(i, 0x20)
            } {
                mstore(add(resultPtr, i), mload(add(dataPtr, i)))
            }
        }

        return result;
    }
}


