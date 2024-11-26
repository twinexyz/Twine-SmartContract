// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

enum VerificationState {
    Verifying,
    Verifiable,
    Verified,
    NotInitializable
}

interface IReceiveUlnView {
    /// @dev a ULN verifiable requires it to be endpoint verifiable and committable
    function verifiable(bytes calldata _packetHeader, bytes32 _payloadHash) external view returns (VerificationState);
}
