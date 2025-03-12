// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";

contract L1MessageQueue is ContextUpgradeable, IL1MessageQueue {
    using TypeConversionLib for string;
    using TypeConversionLib for address;
    // using TypeConversionLib for uint256;
    /*************
     * Variables *
     *************/
    uint64 chainId;
    uint64 depositMessageIndex;
    uint64 withdrawalMessageIndex;
    address public messenger;
    address public roleManager;
    address public messageQueueProxy;

    /**********
     * Queues *
     **********/
    /// @notice The list of queued cross domain messages.
    MessageData[] public depositMessageQueue;

    /// @notice The list of queued cross domain Withdrawal messages.
    MessageData[] public withdrawalMessageQueue;

    /// @notice The list of queued layer zero messages.
    MessageData[] public layerZeroMessageQueue;

    /// @notice The list of queued transactions that are ready for execution.
    MessageData[] public executionMessageQueue;

    /**********************
     * Function Modifiers *
     **********************/
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

    /// @custom:oz-upgrades-unsafe-allow constructor external-library-linking
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

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainDepositMessageIndex()
        public
        view
        returns (uint256)
    {
        return depositMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainWithdrawalMessageIndex()
        public
        view
        returns (uint256)
    {
        return withdrawalMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainExecutionMessageIndex()
        public
        view
        returns (uint256)
    {
        return executionMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function getCrossDomainDepositMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory) {
        require(
            nextCrossDomainDepositMessageIndex() > queueIndex,
            "Invalid index"
        );
        return depositMessageQueue[queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function getCrossDomainWithdrawalMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory) {
        require(
            nextCrossDomainWithdrawalMessageIndex() > queueIndex,
            "Invalid index"
        );
        return withdrawalMessageQueue[queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function getCrossDomainLayerZeroMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory) {
        return layerZeroMessageQueue[queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function getExecutionMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory) {
        require(
            nextCrossDomainExecutionMessageIndex() > queueIndex,
            "Invalid index"
        );
        return executionMessageQueue[queueIndex];
    }

    function padAddress(address input) external pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL1MessageQueue
    function setMessengerAddress(
        address _messenger
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_messenger == address(0)) {
            revert ErrorZeroAddress();
        }
        messenger = _messenger;
    }

    /// @inheritdoc IL1MessageQueue
    function setChainId(
        uint64 _chainId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        chainId = _chainId;
    }

    /// @inheritdoc IL1MessageQueue
    function setRoleManager(
        address _roleManager
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_roleManager == address(0)) {
            revert ErrorZeroAddress();
        }
        roleManager = _roleManager;
    }

    /// @inheritdoc IL1MessageQueue
    function setMessageQueueProxy(
        address _proxyAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_proxyAddress == address(0)) {
            revert ErrorZeroAddress();
        }
        messageQueueProxy = _proxyAddress;
    }

    function isNonceInExecutionQueue(
        uint256 nonce
    ) external view returns (bool) {
        uint256 len = executionMessageQueue.length;
        for (uint256 i = 0; i < len; i++) {
            if (executionMessageQueue[i].nonce == nonce) {
                return true;
            }
        }
        return false;
    }

    function removeExecutionMessage(uint256 nonce) external onlyRoles(IRoleManager(roleManager).TWINE_CHAIN()) {
        uint256 len = executionMessageQueue.length;
        for (uint256 i = 0; i < len; i++) {
            if (executionMessageQueue[i].nonce == nonce) {
                for (uint256 j = i; j < len - 1; j++) {
                    executionMessageQueue[j] = executionMessageQueue[j + 1];
                }
                executionMessageQueue.pop();
            }
        }
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNDepositElement(uint256 n) external onlyRoles(IRoleManager(roleManager).TWINE_CHAIN()) {
        uint256 len = depositMessageQueue.length;
        require(n <= nextCrossDomainDepositMessageIndex(), "Invalid index");
        // Shift elements
        for (uint256 i = 0; i < len - n; i++) {
            depositMessageQueue[i] = depositMessageQueue[i + n];
        }

        // Remove the last n elements by reducing the array length
        for (uint256 i = 0; i < n; i++) {
            depositMessageQueue.pop();
        }
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNWithdrawalElement(uint256 n) external onlyRoles(IRoleManager(roleManager).TWINE_CHAIN()) {
        uint256 len = withdrawalMessageQueue.length;
        require(n <= nextCrossDomainWithdrawalMessageIndex(), "Invalid index");
        // Shift elements
        for (uint256 i = 0; i < len - n; i++) {
            withdrawalMessageQueue[i] = withdrawalMessageQueue[i + n];
        }

        // Remove the last n elements by reducing the array length
        for (uint256 i = 0; i < n; i++) {
            withdrawalMessageQueue.pop();
        }
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNLayerZeroElement(uint256 n) external onlyRoles(IRoleManager(roleManager).TWINE_CHAIN()) {
        uint256 len = layerZeroMessageQueue.length;
        for (uint256 i = 0; i < len - n; i++) {
            layerZeroMessageQueue[i] = layerZeroMessageQueue[i + n];
        }

        // Remove the last n elements by reducing the array length
        for (uint256 i = 0; i < n; i++) {
            layerZeroMessageQueue.pop();
        }
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainDepositMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount
    ) external override onlyMessenger {
        _queueDepositTransaction(from, to, l1Token, l2Token, amount);
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainWithdrawalMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount
    ) external override onlyMessenger {
        _queueWithdrawalTransaction(from, to, l1Token, l2Token, amount);
    }

    /// @inheritdoc IL1MessageQueue
    function appendExecutionMessage(
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        string memory from,
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) external override onlyRoles(IRoleManager(roleManager).TWINE_CHAIN()) {
        _queueExecutionTransaction(
            nonce,
            chainId,
            blockNumber,
            from,
            to,
            l1Token,
            l2Token,
            amount
        );
    }

    /**********************
     * Internal Functions *
     **********************/

    function _queueDepositTransaction(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount
    ) internal {
        ++depositMessageIndex;

        MessageData memory depositMessageData = MessageData({
            nonce: depositMessageIndex,
            chainId: chainId,
            blockNumber: uint64(block.number),
            fromAddress: from.addressToString(),
            toAddress: to.addressToString(),
            l1Token: l1Token.addressToString(),
            l2Token: l2Token.addressToString(),
            amount: uintToString(amount)
        });

        depositMessageQueue.push(depositMessageData);

        // emit event
        emit QueueDepositTransaction(
            depositMessageIndex,
            chainId,
            uint64(block.number),
            l1Token,
            l2Token,
            from,
            to,
            amount
        );
    }

    function _queueWithdrawalTransaction(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount
    ) internal {
        ++withdrawalMessageIndex;

        MessageData memory withdrawMessageData = MessageData({
            nonce: withdrawalMessageIndex,
            chainId: chainId,
            blockNumber: uint64(block.number),
            fromAddress: from.addressToString(),
            toAddress: to.addressToString(),
            l1Token: l1Token.addressToString(),
            l2Token: l2Token.addressToString(),
            amount: uintToString(amount)
        });

        withdrawalMessageQueue.push(withdrawMessageData);

        // emit event
        emit QueueWithdrawalTransaction(
            withdrawalMessageIndex,
            chainId,
            uint64(block.number),
            l1Token,
            l2Token,
            from,
            to,
            amount
        );
    }

    function _queueExecutionTransaction(
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        string memory from,
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) internal {
        MessageData memory executionMessageData = MessageData({
            nonce: nonce,
            chainId: chainId,
            blockNumber: blockNumber,
            fromAddress: from,
            toAddress: to,
            l1Token: l1Token,
            l2Token: l2Token,
            amount: amount
        });

        executionMessageQueue.push(executionMessageData);
    }

    /// @notice Converts a uint256 to its string representation
    /// @param value The uint256 value to convert
    /// @return The string representation of the input value
    function uintToString(
        uint256 value
    ) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
}
