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
        uint256 amount
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
        uint256 amount
    );

    /**********
     * Errors *
     **********/

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /**********
     * Struct *
     **********/

    /// @notice Deposit message stored data
    /// @param nonce the nonce of the message
    /// @param toAddress the Twine address to deposit into
    /// @param l1Token the address of token to deposit on l1
    /// @param l2Token the address of token to receive on l2
    /// @param chainId chain id of the l1 where deposit is initiated
    /// @param amount amount of token to deposit
    /// @param blockNumber block number on which deposit occured
    struct MessageData {
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

    /// @notice Return the index of next appended message.
    /// @dev Also the total number of appended messages.
    function nextCrossDomainDepositMessageIndex()
        external
        view
        returns (uint256);

    /// @notice Return the index of next appended message.
    /// @dev Also the total number of appended messages.
    function nextCrossDomainWithdrawalMessageIndex()
        external
        view
        returns (uint256);

    /// @notice Return the index of next appended message.
    /// @dev Also the total number of appended messages.
    function nextCrossDomainExecutionMessageIndex()
        external
        view
        returns (uint256);

    /// @notice Return the deposit message of in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainDepositMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory);

    /// @notice Return the withdraw message of in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainWithdrawalMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory);

    /// @notice Return the layer zero message in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainLayerZeroMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory);

    /// @notice Return the execution message in `queueIndex`.
    /// @param queueIndex The index to query.
    function getExecutionMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory);

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

    /// @notice Checks if the nonce provided is present in execution message queue or not
    /// @param nonce Nonce to check
    function isNonceInExecutionQueue(
        uint256 nonce
    ) external view returns (bool);

    /// @notice Remove message with the given nonce from the execution message queue
    /// @param nonce The nonce of the message to be removed
    function removeExecutionMessage(uint256 nonce) external;

    /// @notice Removes the first N message from the Deposit Queue
    /// @param n number of deposit message to pop
    function popFirstNDepositElement(uint256 n) external;

    /// @notice Removes the first N message from the Withdrawal Queue
    /// @param n number of withdraw message  to pop
    function popFirstNWithdrawalElement(uint256 n) external;

    /// @notice Removes the first N message from the Layer Zero Queue
    /// @param n number of lz message to pop
    function popFirstNLayerZeroElement(uint256 n) external;

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

    /// @notice Append message that are ready for execution
    /// @param nonce the nonce of the message
    /// @param chainId chain Id of L1
    /// @param blockNumber L2 block number in which this transaction was present
    /// @param from the sender address
    /// @param to the receiver address
    /// @param l1Token adress of token to be received on l1
    /// @param l2Token adress of token withdrawan from Twine
    /// @param amount amount to be received on L1
    function appendExecutionMessage(
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        string memory from,
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount,
        bytes memory message
    ) external;
}
