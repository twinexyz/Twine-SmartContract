// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL1MessageQueue {
     /**********
     * Events *
     **********/

    /// @notice Emitted when a new L1 => L2  deposit transaction is appended to the queue.
    /// @param from The address of account who initiates the transaction.
    /// @param to The address of receiver
     /// @param counterpart The address of the counterpart gateway.
    /// @param value The value passed with the transaction.
    /// @param chainId The id of the L1 chain
    /// @param depositMessageIndex The index of the transaction.
    /// @param gasLimit Gas limit required to complete the message relay on L2.
    /// @param data The calldata of the transaction.
    event QueueDepositTransaction(
        address indexed from,
        address to,
        address counterpart,
        uint256 value,
        uint256 chainId,
        uint256 depositMessageIndex,
        uint256 gasLimit,
        uint256 blockNumber,
        bytes data
    );

    /// @notice Emitted when a new L1 => L2 forced withdrawal transaction is appended to the queue.
    /// @param from The address of account who initiates the transaction.
    /// @param to The address of receiver
    /// @param counterpart The address of the counterpart gateway.
    /// @param value The value passed with the transaction.
    /// @param chainId The id of the L1 chain
    /// @param withdrawalMessageIndex The index of the transaction
    /// @param gasLimit Gas limit required to complete the message relay on L2.
    /// @param data The calldata of the transaction.
    event QueueWithdrawalTransaction(
        address indexed from,
        address to,
        address counterpart,
        uint256 value,
        uint256 chainId,
        uint256 withdrawalMessageIndex,
        uint256 gasLimit,
        uint256 blockNumber,
        bytes data
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
        address messageQueueAddress;
        bytes32 fromAddressHash;
        bytes dataValuesByte;
    }
    struct MessageDataTest {
        address messageQueueAddress;
        bytes32 l1AddressHash;
        bytes32 l2AddressHash;
        bytes32 fromAddressHash;
        bytes dataValuesByte;
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

    /// @notice Return the amount of ETH should pay for cross domain message.
    /// @param gasLimit Gas limit required to complete the message relay on L2.
    //function estimateCrossDomainMessageFee(uint256 gasLimit) external view returns (uint256);

    /// @notice Append a L1 to L2 deposit message into this contract.
    /// @param _counterpart The address of target contract to call in L2.
    /// @param _gasLimit The maximum gas should be used for relay this message in L2.
    /// @param _data The calldata passed to target contract.
    function appendCrossDomainDepositMessage(
        address _from,
        address _to,
        address _counterpart,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external;

    /// @notice Append a L1 to L2 withdrawal message into this contract.
    /// @param _counterpart The address of target contract to call in L2.
    /// @param _from The address of the sender
    /// @param _to The address of the receiver
    /// @param _gasLimit The maximum gas should be used for relay this message in L2.
    /// @param _data The calldata passed to target contract.
    function appendCrossDomainWithdrawalMessage(
        address _from,
        address _to,
        address _counterpart,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external;
}