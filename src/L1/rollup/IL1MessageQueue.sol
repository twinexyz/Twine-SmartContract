// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL1MessageQueue {
     /**********
     * Events *
     **********/

    /// @notice Emitted when a new L1 => L2  deposit transaction is appended to the queue.
    /// @param nonce The nonce of the message.
    /// @param to_twine_address The address of receiver.
    /// @param l1_token Address of token to send from L1.
    /// @param l2_token address of token to receive on L2.
    /// @param chainId Chain Id of this L1.
    /// @param amount The amount of token to send.
    /// @param block_number The block number in which this transaction occured.
    event QueueDepositTransaction(
        uint64 nonce,
        string to_twine_address,
        string l1_token,
        string l2_token,
        uint64 chainId,
        string amount,
        uint64 block_number
    );

    /// @notice Emitted when a new L1 => L2 forced withdrawal transaction is appended to the queue.
    /// @param nonce The nonce of the message.
    /// @param to_twine_address The address of receiver.
    /// @param l1_token Address of token to receive on L1.
    /// @param l2_token address of token to send from L2.
    /// @param chainId Chain Id of this L1.
    /// @param amount The amount of token to send.
    /// @param block_number The block number in which this transaction occured.
    event QueueWithdrawalTransaction(
        uint64 nonce,
        string to_twine_address,
        string l1_token,
        string l2_token,
        uint64 chainId,
        string amount,
        uint64 block_number
    );

    /**********
     * Errors *
     **********/

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /**********
     * Struct *
     **********/

    struct MessageData {
        uint64 nonce;
        string to_address;
        string l1_token;
        string l2_token;
        uint64 chainId;
        string amount;
        uint64 block_number;
    }

    /// @notice Return the index of next appended message.
    /// @dev Also the total number of appended messages.
    function nextCrossDomainDepositMessageIndex() external view returns (uint256);

    /// @notice Return the index of next appended message.
    /// @dev Also the total number of appended messages.
    function nextCrossDomainWithdrawalMessageIndex() external view returns (uint256);


    /// @notice Return the message of in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainDepositMessage(uint256 queueIndex) external view returns (MessageData memory);

    /// @notice Return the message of in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainWithdrawalMessage(uint256 queueIndex) external view returns (MessageData memory);
    
    /// @notice Removes the first N message from the Deposit Queue
    function popFirstNDepositElement(uint n) external;

    /// @notice Removes the first N message from the Withdrawal Queue
    function popFirstNWithdrawalElement(uint n) external;

    ///@notice set the proxy Address of MessageQueue
    function setMessageQueueProxy(address proxyAddress) external;

    function appendCrossDomainDepositMessage(
        string memory to,
        string memory l1_token,
        string memory l2_token,
        string memory amount
    ) external;

    function appendCrossDomainWithdrawalMessage(
        string memory to,
        string memory l1_token,
        string memory l2_token,
        string memory amount
    ) external;
}