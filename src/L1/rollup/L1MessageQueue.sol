// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";

contract L1MessageQueue is ContextUpgradeable, IL1MessageQueue {
    /// @notice The address of L1TwineMessenger contract.
    uint64 chainId;
    uint64 depositMessageIndex;
    uint64 withdrawalMessageIndex;
    address public messenger;
    address public messageQueueProxy;
    address public roleManager;

    /// @notice The list of queued cross domain messages.
    MessageData[] public depositMessageQueue;

    /// @notice The list of queued cross domain Withdrawal messages.
    MessageData[] public withdrawalMessageQueue;

    /// @notice The list of queued transactions that are ready for execution.
    MessageData[] public executionMessageQueue;

    modifier onlyMessenger() {
        require(
            _msgSender() == messenger,
            "Only callable by the L1TwineMessenger"
        );
        _;
    }

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // @notice Initialize the storage of L1MessageQueue.
    /// @param _chainId The chain id of L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
    /// @param _roleManager The address of roleManager Contract.
    function initialize(
        uint64 _chainId,
        address _messenger,
        address _roleManager
    ) external initializer {
        messenger = _messenger;
        chainId = _chainId;
        roleManager = _roleManager;
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNDepositElement(uint n) external {
        // Shift elements
        for (uint i = 0; i < depositMessageQueue.length - n; i++) {
            depositMessageQueue[i] = depositMessageQueue[i + n];
        }

        // Remove the last n elements by reducing the array length
        for (uint i = 0; i < n; i++) {
            depositMessageQueue.pop();
        }
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNWithdrawalElement(uint n) external {
        // Shift elements
        for (uint i = 0; i < withdrawalMessageQueue.length - n; i++) {
            withdrawalMessageQueue[i] = withdrawalMessageQueue[i + n];
        }

        // Remove the last n elements by reducing the array length
        for (uint i = 0; i < n; i++) {
            withdrawalMessageQueue.pop();
        }
    }

    function getCrossDomainDepositMessage(
        uint256 _queueIndex
    ) external view returns (MessageData memory) {
        return depositMessageQueue[_queueIndex];
    }

    function getCrossDomainWithdrawalMessage(
        uint256 _queueIndex
    ) external view returns (MessageData memory) {
        return withdrawalMessageQueue[_queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainDepositMessage(
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) external override onlyMessenger {
        _queueDepositTransaction(to, l1Token, l2Token, amount);
    }

    /// @inheritdoc IL1MessageQueue
    function appendExecutionMessage(
        uint64 _nonce,
        string memory _to,
        string memory _l1Token,
        string memory _l2Token,
        uint64 _chainId,
        string memory _amount,
        uint64 _blockNumber
    ) external override {
        _queueExecutionTransaction(
            _nonce,
            _to,
            _l1Token,
            _l2Token,
            _chainId,
            _amount,
            _blockNumber
        );
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainWithdrawalMessage(
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) external override onlyMessenger {
        _queueWithdrawalTransaction(to, l1Token, l2Token, amount);
    }

    function _queueDepositTransaction(
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) internal {
        ++depositMessageIndex;

        MessageData memory depositMessageData = MessageData({
            nonce: depositMessageIndex,
            toAddress: to,
            l1Token: l1Token,
            l2Token: l2Token,
            chainId: chainId,
            amount: amount,
            blockNumber: uint64(block.number)
        });

        depositMessageQueue.push(depositMessageData);

        // emit event
        emit QueueDepositTransaction(
            depositMessageIndex,
            to,
            l1Token,
            l2Token,
            chainId,
            amount,
            uint64(block.number)
        );
    }

    function _queueWithdrawalTransaction(
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) internal {
        ++withdrawalMessageIndex;

        MessageData memory withdrawMessageData = MessageData({
            nonce: depositMessageIndex,
            toAddress: to,
            l1Token: l1Token,
            l2Token: l2Token,
            chainId: chainId,
            amount: amount,
            blockNumber: uint64(block.number)
        });

        withdrawalMessageQueue.push(withdrawMessageData);

        // emit event
        emit QueueWithdrawalTransaction(
            withdrawalMessageIndex,
            to,
            l1Token,
            l2Token,
            chainId,
            amount,
            uint64(block.number)
        );
    }

    function _queueExecutionTransaction(
        uint64 _nonce,
        string memory _to,
        string memory _l1Token,
        string memory _l2Token,
        uint64 _chainId,
        string memory _amount,
        uint64 _blockNumber
    ) internal {
        MessageData memory executionMessageData = MessageData({
            nonce: _nonce,
            toAddress: _to,
            l1Token: _l1Token,
            l2Token: _l2Token,
            chainId: _chainId,
            amount: _amount,
            blockNumber: _blockNumber
        });

        executionMessageQueue.push(executionMessageData);
    }

    function _padAddress(address input) public pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    function setMessengerAddress(
        address _messenger
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        messenger = _messenger;
    }

    function setChainId(
        uint64 _chainId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        chainId = _chainId;
    }

    function setRoleManager(
        address _roleManager
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        roleManager = _roleManager;
    }

    function setMessageQueueProxy(
        address _proxyAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        messageQueueProxy = _proxyAddress;
    }
    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainDepositMessageIndex()
        external
        view
        returns (uint256)
    {
        return depositMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainWithdrawalMessageIndex()
        external
        view
        returns (uint256)
    {
        return withdrawalMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainExecutionMessageIndex()
        external
        view
        returns (uint256)
    {
        return executionMessageQueue.length;
    }

    function getExecutionMessage(
        uint256 index
    ) external view returns (MessageData memory) {
        require(index < executionMessageQueue.length, "Invalid index");
        return executionMessageQueue[index];
    }

    function removeExecutionMessage(uint256 index) external {
        require(index < executionMessageQueue.length, "Invalid index");

        // Shift elements to left
        for(uint256 i = index; i < executionMessageQueue.length - 1; i++) {
            executionMessageQueue[i] = executionMessageQueue[i + 1];
        }
        executionMessageQueue.pop();
    }
}
