// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {TwineMessengerBase} from "../libraries/TwineMessengerBase.sol";

contract L2TwineMessenger is TwineMessengerBase, IL2TwineMessenger {
    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is sent.
    /// @param sender The address of the sender who initiates the message.
    /// @param target The address of target contract to call.
    /// @param value The amount of value passed to the target contract.
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    /// @param message The calldata passed to the target contract.
    event SentMessage(
        address indexed sender,
        address indexed target,
        uint256 value,
        uint256 gasLimit,
        bytes message
    );

    /// @notice Mapping from L1 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL1MessageExecuted;

    /// @notice The address of L2MessageQueue.
    address public messageQueue;

    /// @notice The address of Consensus Proving Precompile
    address public consensusPrecompile_address;

    /// @notice The address of deposit Proving and executing Precompile
    address public depositPrecompile_address;

    /// @notice The address of withdrawal Proving Precompile
    address public withdrawalPrecompile_address;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _counterpart, address _messageQueue)
        external
        initializer
    {
        TwineMessengerBase.__TwineMessengerBase_init(_counterpart);
        messageQueue = _messageQueue;
    }

    function setAddress(address _messageQueue) external {
        messageQueue = _messageQueue;
    }

    function sendMessage(
        TransactionType _type,
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit
    ) external payable override {
        _sendMessage(_to, _value, _message, _gasLimit);
    }

    function sendMessage(
        TransactionType _type,
        address _to,
        uint256 _value,
        bytes calldata _message,
        uint256 _gasLimit,
        address
    ) external payable override {
        _sendMessage(_to, _value, _message, _gasLimit);
    }

    function verifyConsensusProof(
        bytes memory headers,
        bytes memory proof
    ) public {
        bytes memory data = abi.encode(headers, proof);
        (bool success, bytes memory output) = consensusPrecompile_address.call(data);
        require(success, "Consensus proof Failed!");
        
    }

    function executeDepositTransactions(
        bytes[] memory depositTransactions,
        bytes memory proof
    ) public {
        bytes memory data = abi.encode(depositTransactions, proof);
        (bool success, bytes memory output) = depositPrecompile_address.call(data);
        require(success, "Deposits failed!");
    }

    function executeIndividualWithdrawal(
        bytes memory withdrawalTransaction,
        bytes memory proof
    ) public {
        bytes memory data = abi.encode(withdrawalTransaction, proof);
        (bool success, bytes memory output) = withdrawalPrecompile_address.call(data);
        require(success, "Withdrawal failed!");
    }

    /// @dev Internal function to send cross domain message.
    /// @param _to The address of account who receive the message.
    /// @param _value The amount of ether passed when call target contract.
    /// @param _message The content of the message.
    /// @param _gasLimit Optional gas limit to complete the message relay on corresponding chain.
    function _sendMessage(
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit
    ) internal {
        require(msg.value == _value, "msg.value mismatch");

        emit SentMessage(_msgSender(), _to, _value, _gasLimit, _message);
    }
}
