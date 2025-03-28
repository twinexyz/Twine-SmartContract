// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineDVN {
    struct PayloadOtherData {
        uint32 dstEid;
        uint64 blockConfirmations;
        address receiverAddress;
        bytes32 payloadHash;
        bytes packetHeader;
    }

    event PayloadVerified(bytes packetHeader, bytes32 payloadHash);
    event SetFee(uint32 dstEid, uint256 fee);
    event DstChainStatusChanged(uint32 dstEid, bool enabled);
    event WithdrawFee(address messageLib, address receiver, uint256 amount);
    event TwineNotified(
        uint32 indexed dstEid,
        uint64 blockConfirmations,
        address receiverAddress,
        uint256 fee,
        uint256 blockNumber,
        bytes32 payloadHash,
        bytes32 guId,
        bytes packetHeader
    );
    function validatePayload(bytes memory payloadData) external returns (bool);
}
