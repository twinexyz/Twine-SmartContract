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
    /// @dev Decode public values for refund and forced withdrawals
    /// @notice It expects address to have `0x` prefix
    function decodeL1OriginTxnPublicValues(
        bytes calldata publicValues
    )
        internal
        pure
        returns (ITwineChain.L1OriginTxPublicValues memory transactionValues)
    {
        require(publicValues.length >= 266, "data too short");

        uint256 offset = 0;

        // batchHash (bytes32)
        transactionValues.batchHash = bytes32(slice(publicValues, offset, 32));
        offset += 32;

        // batchNumber (uint64)
        transactionValues.batchNumber = uint64(
            bytesToUint(slice(publicValues, offset, 8))
        );
        offset += 8;

        // txnType (uint8 assumed for enum)
        transactionValues.txnType = ITwineChain.TransactionType(uint8(publicValues[offset]));
        offset += 1;

        // nonce (uint64)
        transactionValues.nonce = uint64(bytesToUint(slice(publicValues, offset, 8)));
        offset += 8;

        // chainId (uint64)
        transactionValues.chainId = uint64(bytesToUint(slice(publicValues, offset, 8)));
        offset += 8;

        // blockNumber (uint64)
        transactionValues.blockNumber = uint64(
            bytesToUint(slice(publicValues, offset, 8))
        );
        offset += 8;

        // messageHash (bytes32)
        transactionValues.messageHash = bytes32(slice(publicValues, offset, 32));
        offset += 32;

        // fromAddress (string, 42 bytes)
        transactionValues.fromAddress = string(slice(publicValues, offset, 42));
        offset += 42;

        // toAddress (string, 42 bytes)
        transactionValues.toAddress = string(slice(publicValues, offset, 42));
        offset += 42;

        // l1Token (string, 42 bytes)
        transactionValues.l1Token = string(slice(publicValues, offset, 42));
        offset += 42;

        // l2Token (string, 42 bytes)
        transactionValues.l2Token = string(slice(publicValues, offset, 42));
        offset += 42;

        // remaining bytes are amount (string)
        uint256 amountLength = publicValues.length - offset;
        transactionValues.amount = string(slice(publicValues, offset, amountLength));

        return transactionValues;
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
        bytes memory tempBytes = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            tempBytes[i] = data[start + i];
        }
        return tempBytes;
    }

    // Helper: convert bytes to uint (big endian)
    function bytesToUint(bytes memory b) internal pure returns (uint) {
        uint number;
        for (uint i = 0; i < b.length; i++) {
            number =
                number +
                uint(uint8(b[i])) *
                (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }
}

// function slice(
//     bytes memory data,
//     uint256 start,
//     uint256 length
// ) internal pure returns (bytes memory result) {
//     require(data.length >= start + length, "Invalid slice range");

//     result = new bytes(length);

//     assembly {
//         let resultPtr := add(result, 0x20)
//         let dataPtr := add(add(data, 0x20), start)

//         // Number of complete 32-byte words
//         let words := div(add(length, 31), 32)

//         for {
//             let i := 0
//         } lt(i, words) {
//             i := add(i, 1)
//         } {
//             mstore(
//                 add(resultPtr, mul(i, 32)),
//                 mload(add(dataPtr, mul(i, 32)))
//             )
//         }

//         // Mask the last word if length % 32 != 0
//         let lastBytes := mod(length, 32)
//         if lastBytes {
//             let mask := sub(exp(256, sub(32, lastBytes)), 1)
//             mstore(
//                 add(resultPtr, mul(sub(words, 1), 32)),
//                 and(mload(add(dataPtr, mul(sub(words, 1), 32))), not(mask))
//             )
//         }
//     }
// }
