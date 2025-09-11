// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {TwineTypes} from "../types/TwineTypes.sol";
import {TypeConversionLib} from "./TypeConversionLib.sol";

/**
 * @title MessageHasherLib
 * @notice MessageHasherLib hashes messages in correct format
 **/
library MessageHasherLib {
    using TypeConversionLib for string;
    /// @dev This function is used to hash l1 messages 
    /// @notice The message hash is then stored on chain 
    /// @notice The L2 side uses this method to verify message with this hash was executed
    function hashL1Message(
        TwineTypes.MessageData memory messageData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    messageData.txnType,
                    messageData.nonce,
                    messageData.chainId,
                    messageData.blockNumber,
                    keccak256(messageData.message),
                    messageData.fromAddress.toLower(),
                    messageData.toAddress.toLower(),
                    messageData.l1Token.toLower(),
                    messageData.l2Token.toLower(),
                    messageData.amount
                )
            );
    }
}
