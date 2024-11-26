// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineDVN {
    struct PayloadOtherData {
        uint64 blockConfirmation;
        uint120 requiredBlockNumber;
        address receiveLibrary;
        bytes32 payloadHash;
        bytes packetHeader;
    }

    event PayloadVerified(bytes packetHeader,bytes32 payloadHash);
    function validatePayload(bytes memory payloadData) external;
}
