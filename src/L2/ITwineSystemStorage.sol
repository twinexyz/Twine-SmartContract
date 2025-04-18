// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITwineSystemStorage {
    /// @notice All types of messages incoming from L1
    /// @dev Enum used to categorize different transaction types processed by the system.
    enum L1TxnType {
        Deposit,
        ForcedWithdraw,
        LayerZero,
        Message
    }

    ///@notice get the executed nonce according to the txn type
    /// @param chainId The ID of the chain of which transaction is executed
    /// @param txnType The type of the transaction
    function l1MessageExecutedCount(uint256 chainId, L1TxnType txnType) external view returns (uint256);

    /// @notice Sets the receipt root for a specific block on a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param chainId The ID of the chain for which the receipt root is being stored.
    /// @param height The block number (height) for which the receipt root is being stored.
    /// @param receiptRoot The Merkle root of the receipts for the specified block.
    function setBlockReceipts(
        uint256 chainId,
        uint256 height,
        bytes32 receiptRoot
    ) external;

    /// @notice Increments the nonce for a specific transaction type on a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param chainId The ID of the chain for which the nonce is being incremented.
    /// @param txnType The type of transaction for which the nonce is being incremented.
    function increaseNonce(uint256 chainId, L1TxnType txnType) external;
}