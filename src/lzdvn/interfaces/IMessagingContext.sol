// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32 dstEid, address sender);
}
