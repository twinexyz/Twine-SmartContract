// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL1MessageQueue {
    /**********
     * Events *
     **********/

    /// @notice Emitted when a new L1 => L2  deposit transaction is appended to the queue.
    /// @param nonce The nonce of the message.
    /// @param chainId Chain Id of this L1.
    /// @param blockNumber The block number in which this transaction occured.
    /// @param amount The amount of token to send.
    /// @param l1Token Address of token to send from L1.
    /// @param l2Token address of token to receive on L2.
    /// @param toTwineAddress The address of receiver.

    event QueueDepositTransaction(
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        address l1Token,
        address l2Token,
        address from,
        address toTwineAddress,
        uint256 amount,
        bytes message
    );

    /// @notice Emitted when a new L1 => L2 forced withdrawal transaction is appended to the queue.
    /// @param nonce The nonce of the message.
    /// @param chainId Chain Id of this L1.
    /// @param blockNumber The block number in which this transaction occured.
    /// @param amount The amount of token to send.
    /// @param l1Token Address of token to receive on L1.
    /// @param l2Token address of token to send from L2.
    /// @param toTwineAddress The address of receiver.

    event QueueWithdrawalTransaction(
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        address l1Token,
        address l2Token,
        address from,
        address toTwineAddress,
        uint256 amount,
        bytes message
    );

    /// @notice Emitted when a new L1 => L2  deposit transaction is appended to the queue.
    /// @param txnType The transaction type in L1.
    /// @param nonce The nonce of the message.
    /// @param chainId Chain Id of this L1.
    /// @param blockNumber The block number in which this transaction occured.
    /// @param amount The amount of token to send.
    /// @param l1Token Address of token to send from L1.
    /// @param l2Token address of token to receive on L2.
    /// @param toTwineAddress The address of receiver.

    event QueueTransaction(
        TransactionType txnType,
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        address l1Token,
        address l2Token,
        address from,
        address toTwineAddress,
        uint256 amount,
        bytes message
    );

    /**********
     * Errors *
     **********/

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /**********
     * Struct *
     **********/

    /// @notice Transaction type in L1
    /// @param Deposit the deposit transaction type
    /// @param Withdraw the forced withdrawal transaction type
    /// @param Message the normal message type
    enum TransactionType {
        Deposit,
        Withdraw,
        Message
    }

    /// @notice Deposit message stored data
    /// @param nonce the nonce of the message
    /// @param toAddress the Twine address to deposit into
    /// @param l1Token the address of token to deposit on l1
    /// @param l2Token the address of token to receive on l2
    /// @param chainId chain id of the l1 where deposit is initiated
    /// @param amount amount of token to deposit
    /// @param blockNumber block number on which deposit occured
    struct MessageData {
        TransactionType txnType;
        uint64 nonce;
        uint64 chainId;
        uint64 blockNumber;
        string fromAddress;
        string toAddress;
        string l1Token;
        string l2Token;
        string amount;
        bytes message;
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Returns the message hash.
    function getMessageHash(uint256 messageIndex) external view returns(bytes32);

      /// @notice Return the layer zero message in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainLayerZeroMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory);

    /// @return Message index The index of the messages
    function messageIndex() external view returns (uint64);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Sets the messenger address
    /// @param _messenger messenger address to set
    function setMessengerAddress(address _messenger) external;

    /// @notice Sets the chain id
    /// @param _chainId chain id to set
    function setChainId(uint64 _chainId) external;

    /// @notice sets role manager address
    /// @param _roleManager role manager address to set
    function setRoleManager(address _roleManager) external;

    /// @notice set the proxy Address of MessageQueue
    /// @param _proxyAddress message queue proxy address to set
    function setMessageQueueProxy(address _proxyAddress) external;

    /// @notice Append new message to the deposit queue
    /// @param to Address of receiver on Twine
    /// @param l1Token address of token to deposit on L1
    /// @param l2Token address of token to be received on L2
    /// @param amount amount of token to deposit
    function appendCrossDomainDepositMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external;

    /// @notice Append new message to the deposit queue
    /// @param to Address of receiver on L1
    /// @param l1Token address of token to receive on L1
    /// @param l2Token address of token to be withdrawan from L2
    /// @param amount amount of token to withdraw
    function appendCrossDomainWithdrawalMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external;
}
