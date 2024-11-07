// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineMessenger} from "../libraries/ITwineMessenger.sol";
import {Types} from "../libraries/rlp/Types.sol";

interface IL1TwineMessenger is ITwineMessenger {
    /// @notice Relay a L2 => L1 message with message proof.
    /// @param _batchNumber The index of the Batch where the message is contained.
    /// @param _receiptObject The object for the receipt of withdrawal transaction.
    /// @param _mptKey The trie key of the node whose inclusion we are proving.
    /// @param _rlpProof The stack of MPT nodes (starting with the root) that need to be traversed during verification.
    function relayWithdrawal(
        uint256 _batchNumber,
        Types.ReceiptObject memory _receiptObject,
        bytes memory _mptKey,
        bytes memory _rlpProof
    ) external;
}
