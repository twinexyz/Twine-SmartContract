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
        string toAddress;
        string l1Token;
        string l2Token;
        uint64 chainId;
        string amount;
        uint64 blockNumber;
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
    function setMessengerAddress(address _messenger) external;

    /// @notice Sets the chain id
    function setChainId(uint64 _chainId) external;

    /// @notice sets role manager address
    function setRoleManager(address _roleManager) external;

    /// @notice set the proxy Address of MessageQueue
    function setMessageQueueProxy(address proxyAddress) external;

    /// @notice Removes the first N message from the Deposit Queue
    function popFirstNDepositElement(uint n) external;

    /// @notice Removes the first N message from the Withdrawal Queue
    function popFirstNWithdrawalElement(uint n) external;

    /// @notice Removes the first N message from the Layer Zero Queue
    function popFirstNLayerZeroElement(uint n) external;


    /// @notice Append new message to the deposit queue
    function appendCrossDomainDepositMessage(
        string memory to,
        string memory l1_token,
        string memory l2_token,
        string memory amount
    ) external;

    /// @notice Append new message to the deposit queue
    function appendCrossDomainWithdrawalMessage(
        string memory to,
        string memory l1_token,
        string memory l2_token,
        string memory amount
    ) external;

    /// @notice Append new message to the deposit queue
    function appendExecutionMessage(
        uint64 _nonce,
        string memory _to,
        string memory _l1_token,
        string memory _l2_token,
        uint64 _chainId,
        string memory _amount,
        uint64 _block_number
    ) external;

    /// @notice Remove message on index form execution message queue 
    function removeExecutionMessage(uint256 index) external;


}
