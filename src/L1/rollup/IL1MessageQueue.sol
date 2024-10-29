// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL1MessageQueue {
     /**********
     * Events *
     **********/

    /// @notice Emitted when a new L1 => L2 transaction is appended to the queue.
    /// @param sender The address of account who initiates the transaction.
    /// @param target The address of account who will receive the transaction.
    /// @param value The value passed with the transaction.
    /// @param depositMessageIndex The index of the transaction.
    /// @param gasLimit Gas limit required to complete the message relay on L2.
    /// @param data The calldata of the transaction.
    event QueueDepositTransaction(
        address indexed sender,
        address to,
        address indexed target,
        uint256 value,
        uint256 chainId,
        uint256 depositMessageIndex,
        uint256 gasLimit,
        bytes data
    );

    /// @notice Emitted when a new L1 => L2 transaction is appended to the queue.
    /// @param sender The address of account who initiates the transaction.
    /// @param target The address of account who will receive the transaction.
    /// @param value The value passed with the transaction.
    /// @param withdrawalMessageIndex The index of the transaction
    /// @param gasLimit Gas limit required to complete the message relay on L2.
    /// @param data The calldata of the transaction.
    event QueueWithdrawalTransaction(
        address indexed sender,
        address to,
        address indexed target,
        uint256 value,
        uint256 chainId,
        uint256 withdrawalMessageIndex,
        uint256 gasLimit,
        bytes data
    );

    /**********
     * Errors *
     **********/

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();


    /// @notice Return the index of next appended message.
    /// @dev Also the total number of appended messages.
    function nextCrossDomainDepositMessageIndex() external view returns (uint256);

    /// @notice Return the index of next appended message.
    /// @dev Also the total number of appended messages.
    function nextCrossDomainWithdrawalMessageIndex() external view returns (uint256);


    /// @notice Return the message of in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainDepositMessage(uint256 queueIndex) external view returns (bytes memory);

    /// @notice Return the message of in `queueIndex`.
    /// @param queueIndex The index to query.
    function getCrossDomainWithdrawalMessage(uint256 queueIndex) external view returns (bytes memory);

    /// @notice Return the amount of ETH should pay for cross domain message.
    /// @param gasLimit Gas limit required to complete the message relay on L2.
    //function estimateCrossDomainMessageFee(uint256 gasLimit) external view returns (uint256);

    /// @notice Append a L1 to L2 deposit message into this contract.
    /// @param _target The address of target contract to call in L2.
    /// @param _gasLimit The maximum gas should be used for relay this message in L2.
    /// @param _data The calldata passed to target contract.
    function appendCrossDomainDepositMessage(
        address _target,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external;

    /// @notice Append a L1 to L2 withdrawal message into this contract.
    /// @param _target The address of target contract to call in L2.
    /// @param _gasLimit The maximum gas should be used for relay this message in L2.
    /// @param _data The calldata passed to target contract.
    function appendCrossDomainWithdrawalMessage(
        address _target,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external;
}