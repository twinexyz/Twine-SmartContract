// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineGatewayCallback {
    function onTwineGatewayCallback(bytes memory data) external;
}
