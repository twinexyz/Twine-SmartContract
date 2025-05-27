// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITwineSystemStorage} from "./ITwineSystemStorage.sol";

/// @title TwineSystemStorage
/// @author Twine Labs 
/// @notice This contract manages storage for messages incoming from Layer 1 (L1) and tracks receipt roots for blocks.
///         It also maintains a nonce counter for different types of L1 transactions.
///         This is the only contract that can be modified from the twine precomiles
contract TwineSystemStorage is ITwineSystemStorage {
    
    /// @notice Address of the authorized Twine Admin who can set messenger contract
    /// @dev Only this address can initialize the twine messenger address
    address public admin;

    /// @notice Address of the authorized Twine messenger contract
    /// @dev Only this address can call restricted functions in the contract.
    address public twineMessenger;

    /// @notice Mapping to track the number of executed L1 transactions per chain ID and transaction type.
    /// @dev Structure: chainId => L1TxnType => nonce
    ///      This mapping ensures that each transaction type on each chain has its own independent nonce counter.
    mapping(uint256 => mapping(L1TxnType => uint256))
        private l1MessageExecutedCount;

    /// @notice Mapping to store the receipt roots for each block number on each chain.
    /// @dev Structure: chainId => height => receiptRoot
    ///      This mapping allows retrieval of the receipt root for a specific block on a specific chain.
    mapping(uint256 => mapping(uint256 => bytes32)) private blockReceiptRoots;

    /// @notice Modifier to restrict access to functions only callable by the authorized Twine messenger.
    /// @dev Reverts if the caller is not the `twineMessenger`.
    modifier onlyTwineMessenger() {
        require(msg.sender == twineMessenger, "OnlyTwineMessenger");
        _;
    }

    /// @notice Modifier to restrict access to functions only callable by the authorized Twine messenger.
    /// @dev Reverts if the caller is not the `twineMessenger`.
    modifier onlyTwineAdmin() {
        require(msg.sender == admin, "OnlyTwineAdmin");
        _;
    }

    /// @notice Sets the address of the authorized Twine messenger contract.
    /// @dev Can only be called once
    /// @param _twineMessenger The new address of the Twine messenger contract.
    function setInitialTwineMessenger(address _twineMessenger) onlyTwineAdmin external {
        require(_twineMessenger != address(0), "ShouldBeValidMessenger");
        if (twineMessenger == address(0)) {
            twineMessenger = _twineMessenger;
        }
    }

    /// @notice Sets the address of the authorized Twine messenger contract.
    /// @dev Can only be called by the current `twineMessenger`.
    /// @param _twineMessenger The new address of the Twine messenger contract.
    function setTwineMessenger(
        address _twineMessenger
    ) external onlyTwineAdmin() {
        require(_twineMessenger != address(0), "ShouldBeValidMessenger");
        twineMessenger = _twineMessenger;
    }

    /// @notice Get current nonce for chain id and message type
    /// @param _chainId The ID of the chain to get nonce
    /// @param _txnType The type of transaction 
    /// @return nonce Nonce for that chainId and txnType
    function getLastMessageExecuted(uint256 _chainId, L1TxnType _txnType) external view returns(uint256) {
       return l1MessageExecutedCount[_chainId][_txnType];
    }

    /// @notice Get receipt root of chain with chain id `_chainId` and height `_height`  
    /// @param _chainId The ID of the chain to get nonce
    /// @param _height The block height to fetch receipt root at
    /// @return receiptRoot ReceiptRoot of chain at height
    function getReceiptRoot(uint256 _chainId, uint256 _height) external view returns(bytes32) {
        return blockReceiptRoots[_chainId][_height];
    }

    /// @notice Sets the receipt root for a specific block on a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param _chainId The ID of the chain for which the receipt root is being stored.
    /// @param _height The block number (height) for which the receipt root is being stored.
    /// @param _receiptRoot The Merkle root of the receipts for the specified block.
    function setBlockReceipts(
        uint256 _chainId,
        uint256 _height,
        bytes32 _receiptRoot
    ) external onlyTwineMessenger {
        blockReceiptRoots[_chainId][_height] = _receiptRoot;
    }

    /// @notice Increments the nonce for a specific transaction type on a specific chain.
    /// @dev Can only be called by the authorized `twineMessenger`.
    /// @param _chainId The ID of the chain for which the nonce is being incremented.
    /// @param _txnType The type of transaction for which the nonce is being incremented.
    function increaseNonce(
        uint256 _chainId,
        L1TxnType _txnType
    ) external onlyTwineMessenger {
        l1MessageExecutedCount[_chainId][_txnType] += 1;
    }
}