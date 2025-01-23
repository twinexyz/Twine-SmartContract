// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
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
    uint64 layerZeroMessageIndex;
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
        uint256 _queueIndex
    ) external view returns (MessageData memory) {
        require(
            nextCrossDomainDepositMessageIndex() > _queueIndex,
            "Invalid index"
        );
        return depositMessageQueue[_queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function getCrossDomainWithdrawalMessage(
        uint256 _queueIndex
    ) external view returns (MessageData memory) {
        require(
            nextCrossDomainWithdrawalMessageIndex() > _queueIndex,
            "Invalid index"
        );
        return withdrawalMessageQueue[_queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function getCrossDomainLayerZeroMessage(
        uint256 _queueIndex
    ) external view returns (MessageData memory) {
        return layerZeroMessageQueue[_queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function getExecutionMessage(
        uint256 _queueIndex
    ) external view returns (MessageData memory) {
        require(
            nextCrossDomainExecutionMessageIndex() > _queueIndex,
            "Invalid index"
        );
        return executionMessageQueue[_queueIndex];
    }

    function _padAddress(address input) public pure returns (bytes32) {
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
        uint256 _nonce
    ) external view returns (bool) {
        for (uint256 i = 0; i < executionMessageQueue.length; i++) {
            if (executionMessageQueue[i].nonce == _nonce) {
                return true;
            }
        }
        return false;
    }

    function removeExecutionMessage(uint256 nonce) external onlyMessenger {
        for (uint256 i = 0; i < executionMessageQueue.length; i++) {
            if (executionMessageQueue[i].nonce == nonce) {
                for (uint256 j = i; j < executionMessageQueue.length - 1; j++) {
                    executionMessageQueue[j] = executionMessageQueue[j + 1];
                }
                executionMessageQueue.pop();
            }
        }
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNDepositElement(uint n) external onlyMessenger {
        require(n < nextCrossDomainDepositMessageIndex(), "Invalid index");
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
    function popFirstNWithdrawalElement(uint n) external onlyMessenger {
        require(n < nextCrossDomainWithdrawalMessageIndex(), "Invalid index");
        // Shift elements
        for (uint i = 0; i < withdrawalMessageQueue.length - n; i++) {
            withdrawalMessageQueue[i] = withdrawalMessageQueue[i + n];
        }

        // Remove the last n elements by reducing the array length
        for (uint i = 0; i < n; i++) {
            withdrawalMessageQueue.pop();
        }
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstNLayerZeroElement(uint n) external onlyMessenger {
        for (uint i = 0; i < layerZeroMessageQueue.length - n; i++) {
            layerZeroMessageQueue[i] = layerZeroMessageQueue[i + n];
        }

        // Remove the last n elements by reducing the array length
        for (uint i = 0; i < n; i++) {
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
        uint64 _nonce,
        uint64 _chainId,
        uint64 _blockNumber,
        string memory _from,
        string memory _to,
        string memory _l1Token,
        string memory _l2Token,
        string memory _amount
    ) external override onlyMessenger {
        _queueExecutionTransaction(
            _nonce,
            _chainId,
            _blockNumber,
            _from,
            _to,
            _l1Token,
            _l2Token,
            _amount
        );
    }

    /**********************
     * Internal Functions *
     **********************/

    function _queueDepositTransaction(
        address _from,
        address _to,
        address _l1Token,
        address _l2Token,
        uint256 _amount
    ) internal {
        ++depositMessageIndex;

        MessageData memory depositMessageData = MessageData({
            nonce: depositMessageIndex,
            chainId: chainId,
            blockNumber: uint64(block.number),
            fromAddress: _from.addressToString(),
            toAddress: _to.addressToString(),
            l1Token: _l1Token.addressToString(),
            l2Token: _l2Token.addressToString(),
            amount: uintToString(_amount)
        });

        depositMessageQueue.push(depositMessageData);

        // emit event
        emit QueueDepositTransaction(
            depositMessageIndex,
            chainId,
            uint64(block.number),
            _l1Token,
            _l2Token,
            _from,
            _to,
            _amount
        );
    }

    function _queueWithdrawalTransaction(
        address _from,
        address _to,
        address _l1Token,
        address _l2Token,
        uint256 _amount
    ) internal {
        ++withdrawalMessageIndex;

        MessageData memory withdrawMessageData = MessageData({
            nonce: depositMessageIndex,
            chainId: chainId,
            blockNumber: uint64(block.number),
            fromAddress: _from.addressToString(),
            toAddress: _to.addressToString(),
            l1Token: _l1Token.addressToString(),
            l2Token: _l2Token.addressToString(),
            amount: uintToString(_amount)
        });

        withdrawalMessageQueue.push(withdrawMessageData);

        // emit event
        emit QueueWithdrawalTransaction(
            withdrawalMessageIndex,
            chainId,
            uint64(block.number),
            _l1Token,
            _l2Token,
            _from,
            _to,
            _amount
        );
    }

    function _queueExecutionTransaction(
        uint64 _nonce,
        uint64 _chainId,
        uint64 _blockNumber,
        string memory _from,
        string memory _to,
        string memory _l1Token,
        string memory _l2Token,
        string memory _amount
    ) internal {
        MessageData memory executionMessageData = MessageData({
            nonce: _nonce,
            chainId: _chainId,
            blockNumber: _blockNumber,
            fromAddress: _from,
            toAddress: _to,
            l1Token: _l1Token,
            l2Token: _l2Token,
            amount: _amount
        });

        executionMessageQueue.push(executionMessageData);
    }

    /// @notice Converts a uint256 to its string representation
    /// @param _value The uint256 value to convert
    /// @return The string representation of the input value
    function uintToString(
        uint256 _value
    ) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }
}
