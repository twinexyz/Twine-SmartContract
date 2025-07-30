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
    uint64 public override messageIndex;
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

    mapping(uint256 => bytes32) private messageRollingHashes;

    /// @dev The storage slots reserved for future usage.
    uint256[46] private __gap;

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
    function getCrossDomainLayerZeroMessage(
        uint256 queueIndex
    ) external view returns (MessageData memory) {
        return layerZeroMessageQueue[queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function getMessageHash(
        uint256 messageNonce
    ) external view returns (bytes32) {
        require(messageIndex >= messageNonce, "Invalid index");
        return messageRollingHashes[messageNonce];
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

    function removeExecutionMessage(
        uint256 nonce
    ) external onlyRoles(IRoleManager(roleManager).TWINE_CHAIN()) {
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
    function appendCrossDomainDepositMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external override onlyMessenger {
        _queueDepositTransaction(from, to, l1Token, l2Token, amount, message);
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainWithdrawalMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external override onlyMessenger {
        _queueWithdrawalTransaction(
            from,
            to,
            l1Token,
            l2Token,
            amount,
            message
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
        uint256 amount,
        bytes memory message
    ) internal {
        ++messageIndex;

        MessageData memory depositMessageData = MessageData({
            txnType: TransactionType.Deposit,
            nonce: messageIndex,
            chainId: chainId,
            blockNumber: uint64(block.number),
            fromAddress: from.addressToString(),
            toAddress: to.addressToString(),
            l1Token: l1Token.addressToString(),
            l2Token: l2Token.addressToString(),
            amount: uintToString(amount),
            message: message
        });

        bytes32 particularTransactionHash = computeTransactionHash(
            depositMessageData
        );

        bytes32 calculatedRollingHash = keccak256(
            abi.encodePacked(
                particularTransactionHash,
                messageRollingHashes[messageIndex - 1]
            )
        );

        messageRollingHashes[messageIndex] = calculatedRollingHash;

        // emit deposit event
        emit QueueTransaction(
            TransactionType.Deposit,
            messageIndex,
            chainId,
            uint64(block.number),
            l1Token,
            l2Token,
            from,
            to,
            amount,
            message
        );
    }

    function _queueWithdrawalTransaction(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) internal {
        ++messageIndex;

        MessageData memory withdrawMessageData = MessageData({
            txnType: TransactionType.Withdraw,
            nonce: messageIndex,
            chainId: chainId,
            blockNumber: uint64(block.number),
            fromAddress: from.addressToString(),
            toAddress: to.addressToString(),
            l1Token: l1Token.addressToString(),
            l2Token: l2Token.addressToString(),
            amount: uintToString(amount),
            message: message
        });

        bytes32 particularTransactionHash = computeTransactionHash(
            withdrawMessageData
        );

        bytes32 calculatedRollingHash = keccak256(
            abi.encodePacked(
                particularTransactionHash,
                messageRollingHashes[messageIndex - 1]
            )
        );

        messageRollingHashes[messageIndex] = calculatedRollingHash;

        // emit event
        emit QueueTransaction(
            TransactionType.Withdraw,
            messageIndex,
            chainId,
            uint64(block.number),
            l1Token,
            l2Token,
            from,
            to,
            amount,
            message
        );
    }

    function computeTransactionHash(
        MessageData memory transactionData
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    transactionData.txnType,
                    transactionData.nonce,
                    transactionData.chainId,
                    transactionData.blockNumber,
                    transactionData.fromAddress,
                    transactionData.toAddress,
                    transactionData.l1Token,
                    transactionData.l2Token,
                    transactionData.amount,
                    transactionData.message
                )
            );
    }

    /// @notice Converts a uint256 to its string representation
    /// @param value The uint256 value to convert
    /// @return The string representation of the input value
    function uintToString(uint256 value) internal pure returns (string memory) {
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
