// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineMessenger} from "../libraries/ITwineMessenger.sol";
import {ITwineChain} from "./rollup/ITwineChain.sol";

interface IL1TwineMessenger is ITwineMessenger {

    /// @notice Relay a L2 => L1 message with message proof.
    /// @param batchNumber The index of the Batch where the message is contained.
    /// @param _withdrawalTransactionObject The transaction object for the withdrawal transaction.
    /// @param _fromL1 To identify if the withdrawal was initiated from L1 or L2.
    function relayWithdrawal(
        uint256 batchNumber,
        ITwineChain.WithdrawalTransactionObject memory _withdrawalTransactionObject,
        bool _fromL1
    ) external;
}