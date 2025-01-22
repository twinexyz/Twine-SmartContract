// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Types} from "../libraries/rlp/Types.sol";
import {ITwineL1MessengerBase} from "../libraries/messenger/ITwineL1MessengerBase.sol";

interface IL1TwineMessenger is ITwineL1MessengerBase {
    /**********
    * Events *
    **********/
    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);

    event WithdrawalSuccessful(
        address l1Token,
        address l2Token,
        address recipient,
        uint256 amount
    );

    /*****************************
     * Public Mutating Functions *
     *****************************/
    /// @notice sets the message queue address
    /// @param _messageQueue the address of message queue to set
    function setMessengerQueueAddress(address _messageQueue) external;

    /// @notice sets the twine chain address
    /// @param _rollup the adress of twine chain to set
    function setRollupAddress(address _rollup) external;



}
