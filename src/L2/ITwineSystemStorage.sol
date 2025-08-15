// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineSystemStorage {
    /// @notice Get current nonce for chain id and message type
    /// @param _chainId The ID of the chain to get nonce
    /// @return nonce Nonce for that chainId and txnType
    function getLastMessageExecuted(
        uint256 _chainId
    ) external returns (uint256);

    /// @notice Get bank hash of chain with chain id `_chainId` and height `_slot`
    /// @param _chainId The ID of the chain to get nonce
    /// @param _slot The block height to fetch bank hash at
    /// @return bankHash Bank Hash of chain at slot
    function getBankHash(
        uint256 _chainId,
        uint256 _slot
    ) external returns (bytes32);

    /// @notice Sets the bank hash for a specific slot on a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param _chainId The ID of the chain for which the bank hash is being stored.
    /// @param _slot Slot for which the bank hash is being stored.
    /// @param _bankHash The bank hash for slot
    function setBankHash(
        uint256 _chainId,
        uint256 _slot,
        bytes32 _bankHash
    ) external;

    /// @notice Increments the nonce for a specific transaction type on a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param chainId The ID of the chain for which the nonce is being incremented.
    function increaseNonce(uint256 chainId) external;

    /// @notice Check if a L1 message was executed on Twine
    /// @param messageHash The messageHash of L1 chain to check if it was executed on L2
    /// @return bool If the `L1` message with `messageHash` was executed
    function isMessageExecuted(
        bytes32 messageHash
    ) external view returns (bool);

    /// @notice Set Message Executed
    /// @param messageHash The messageHash of L1 chain to check if it was executed on L2
    function setMessageExecuted(bytes32 messageHash) external;
}
