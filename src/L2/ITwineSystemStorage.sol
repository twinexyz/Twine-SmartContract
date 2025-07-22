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

    /// @notice Get current nonce for chain id and message type
    /// @param _chainId The ID of the chain to get nonce
    /// @param _txnType The type of transaction 
    /// @return nonce Nonce for that chainId and txnType
    function getLastMessageExecuted(uint256 _chainId, L1TxnType _txnType) external returns(uint256);
    
    /// @notice Get receipt root of chain with chain id `_chainId` and height `_height`  
    /// @param _chainId The ID of the chain to get nonce
    /// @param _height The block height to fetch receipt root at
    /// @return receiptRoot ReceiptRoot of chain at height
    function getReceiptRoot(uint256 _chainId, uint256 _height) external returns(bytes32);

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

    /// @notice Sets the last verified header hash for a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param _chainId The ID of the chain whose header is to be stored
    /// @param _headerHash The hash of the header whose consensus proof was verified on twine 
    function setLastVerifiedHeaderHash(uint256 _chainId, bytes32 _headerHash) external;

    /// @notice Get last verified header hash of chain with chain id `_chainId`
    /// @param _chainId The ID of the chain to get nonce
    /// @return headerHash HeaderHash of chain 
    function getLastVerifiedHeaderHash(uint256 _chainId) external returns(bytes32);

    /// @notice Increments the nonce for a specific transaction type on a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param chainId The ID of the chain for which the nonce is being incremented.
    /// @param txnType The type of transaction for which the nonce is being incremented.
    function increaseNonce(uint256 chainId, L1TxnType txnType) external;
}