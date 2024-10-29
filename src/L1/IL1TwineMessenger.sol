// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineMessenger} from "../libraries/ITwineMessenger.sol";
import {ITwineChain} from "./rollup/ITwineChain.sol";

interface IL1TwineMessenger is ITwineMessenger {

    /// @notice Relay a L2 => L1 message with message proof.
    /// @param _batchNumber The index of the Batch where the message is contained.
    /// @param _receiptObject The object for the receipt of withdrawal transaction.
    /// @param _merkleProof The merkle proof of the receiptObject in receiptRoot
    function relayWithdrawal(
        uint256 _batchNumber,
        ITwineChain.ReceiptObject memory _receiptObject,
        bytes32[] memory _merkleProof
    ) external;
}