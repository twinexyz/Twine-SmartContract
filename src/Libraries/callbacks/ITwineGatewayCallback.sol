// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITwineGatewayCallback {
    function onScrollGatewayCallback(bytes memory data) external;
}
