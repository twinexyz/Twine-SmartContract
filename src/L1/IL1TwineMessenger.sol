// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITwineMessenger} from "../libraries/ITwineMessenger.sol";
interface IL1TwineMessenger is ITwineMessenger {


    struct L2MessageProof {
        // The index of the batch where the message belongs to.
        uint256 batchIndex;
        // Concatenation of merkle proof for withdraw merkle trie.
        bytes merkleProof;
    }

    /// @notice Relay a L2 => L1 message with message proof.
    /// @param batchNumber The index of the Batch where the message is contained.
    /// @param from The address of the sender of the message.
    /// @param to The address of the recipient of the message.
    /// @param value The msg.value passed to the message call.
    /// @param message The content of the message.
    function relayMessageWithProof(
        uint256 batchNumber,
        address from,
        address to,
        uint256 value,
        bytes memory message
    ) external;
}