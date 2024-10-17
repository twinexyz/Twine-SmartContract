// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITwineGatewayCallback {
    function onTwineGatewayCallback(bytes memory data) external;
}
