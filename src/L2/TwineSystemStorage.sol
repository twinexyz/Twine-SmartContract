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
    mapping(uint256 => uint256) public l1MessageExecutedCount;

    /// @notice Mapping to track if a L1 message was executed
    /// @dev The hash of the message sent from L1 is the key
    mapping(bytes32 => L1MessageStatus) public l1MessageExecuted;

    /// @notice Mapping to store the bank hashes for each slot number on each chain.
    /// @notice This is done for solana or solana like chains, not needed for ethereum
    /// @dev Structure: chainId => slot => bankHash
    ///      This mapping allows retrieval of the bank hash  for a specific slot on a specific chain.
    mapping(uint256 => mapping(uint256 => bytes32)) private bankHashes;

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
    /// @dev Can only be called by the current `twineMessenger`.
    /// @param _twineMessenger The new address of the Twine messenger contract.
    function setTwineMessenger(
        address _twineMessenger
    ) external onlyTwineAdmin {
        require(_twineMessenger != address(0), "ShouldBeValidMessenger");
        twineMessenger = _twineMessenger;
    }

    /// @inheritdoc ITwineSystemStorage
    function getLastMessageExecuted(
        uint256 _chainId
    ) external view returns (uint256) {
        return l1MessageExecutedCount[_chainId];
    }

    /// @inheritdoc ITwineSystemStorage
    function getBankHash(
        uint256 _chainId,
        uint256 _slot
    ) external view returns (bytes32) {
        return bankHashes[_chainId][_slot];
    }

    /// @inheritdoc ITwineSystemStorage
    function setBankHash(
        uint256 _chainId,
        uint256 _slot,
        bytes32 _bankHash
    ) external onlyTwineMessenger {
        bankHashes[_chainId][_slot] = _bankHash;
    }

    /// @inheritdoc ITwineSystemStorage
    function increaseNonce(uint256 _chainId) external onlyTwineMessenger {
        l1MessageExecutedCount[_chainId] += 1;
    }

    /// @inheritdoc ITwineSystemStorage
    function getMessageStatus(
        bytes32 messageHash
    ) external view returns (L1MessageStatus) {
        return l1MessageExecuted[messageHash];
    }

    /// @inheritdoc ITwineSystemStorage
    function isMessageHandled(
        bytes32 messageHash
    ) external view returns (bool) {
        bool unprocessed = l1MessageExecuted[messageHash] == L1MessageStatus.Unprocessed;
        return !unprocessed;
    }

    /// @inheritdoc ITwineSystemStorage
    function setMessageExecuted(
        bytes32 messageHash,
        L1MessageStatus status
    ) external onlyTwineMessenger {
        l1MessageExecuted[messageHash] = status;
    }
}
