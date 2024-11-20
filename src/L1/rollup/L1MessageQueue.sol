// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";

contract L1MessageQueue is ContextUpgradeable, IL1MessageQueue {
    /// @notice The address of L1TwineMessenger contract.
    uint256 chainId;
    uint256 depositMessageIndex;
    uint256 withdrawalMessageIndex;
    address public messenger;
    address messageQueueProxy;
    address public roleManager;

    /// @notice The list of queued cross domain messages.
    MessageData[] public depositMessageQueue;

    /// @notice The list of queued cross domain Withdrawal messages.
    MessageData[] public withdrawalMessageQueue;

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
        uint256 _chainId,
        address _messenger,
        address _roleManager
    ) external initializer {
        messenger = _messenger;
        chainId = _chainId;
        roleManager = _roleManager;
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNDepositElement(uint n) external {
        require(depositMessageQueue.length > 0, "Array is empty");

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
        require(withdrawalMessageQueue.length > 0, "Array is empty");

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
        address _from,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external override onlyMessenger {
        _queueDepositTransaction(
            _from,
            _to,
            _value,
            _gasLimit,
            _data
        );
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainWithdrawalMessage(
        address _from,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external onlyMessenger {
        _queueWithdrawalTransaction(
            _from,
            _to,
            _value,
            _gasLimit,
            _data
        );
    }

    /// @dev Internal function to queue a L1 transaction.
    /// @param _from The address of sender
    ///@param _to The address of the receiver
    /// @param _value The value passed
    /// @param _gasLimit The maximum gas should be used for this transaction in L2.
    /// @param _data The calldata passed to target contract.
    function _queueDepositTransaction(
        address _from,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) internal {
        ++depositMessageIndex;

        bytes memory depositMessageByteCode = abi.encode(
            _to,
            _value,
            depositMessageIndex,
            _gasLimit,
            block.number,
            _data
        );

        MessageData memory depositMessageData = MessageData({
            messageQueueAddress: messageQueueProxy,
            fromAddressHash: _padAddress(_from),
            chainIdHash: _padAddress(_from),//@note need to change
            dataValuesByte: depositMessageByteCode
        });

        depositMessageQueue.push(depositMessageData);

        // emit event
        emit QueueDepositTransaction(
            _from,
            _to,
            _value,
            chainId,
            depositMessageIndex,
            _gasLimit,
            block.number,
            _data
        );
    }

    function _queueWithdrawalTransaction(
        address _from,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) internal {
        ++withdrawalMessageIndex;
        bytes memory withdrawMessageByteCode = abi.encode(
            _to,
            _value,
            chainId,
            withdrawalMessageIndex,
            _gasLimit,
            block.number,
            _data
        );

        MessageData memory withdrawMessageData = MessageData({
            messageQueueAddress: messageQueueProxy,
            fromAddressHash: _padAddress(_from),
            chainIdHash: _padAddress(_from),//@note need to change hash
            dataValuesByte: withdrawMessageByteCode
        });
        withdrawalMessageQueue.push(withdrawMessageData);

        // emit event
        emit QueueWithdrawalTransaction(
            _from,
            _to,
            _value,
            chainId,
            depositMessageIndex,
            _gasLimit,
            block.number,
            _data
        );
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
        uint256 _chainId
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
}
