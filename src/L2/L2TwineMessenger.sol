// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {L2MessageQueue} from "./predeploys/L2MessageQueue.sol";
import {TwineMessengerBase} from "../libraries/TwineMessengerBase.sol";

contract L2TwineMessenger is TwineMessengerBase,IL2TwineMessenger {
    
    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);

    /// @notice Mapping from L1 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL1MessageExecuted;

    /// @notice The address of L2MessageQueue.
    address public immutable messageQueue;

    constructor(address _counterpart, address _messageQueue) TwineMessengerBase(_counterpart){
        counterpart = _counterpart;
        
        _disableInitializers();

        messageQueue = _messageQueue;
    }

    function initialize(address) external initializer {
        TwineMessengerBase.__TwineMessengerBase_init(address(0), address(0));
    }

    function sendMessage(
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit
    ) external payable override  {
        _sendMessage(_to, _value, _message, _gasLimit);
    }

   
    function sendMessage(
        address _to,
        uint256 _value,
        bytes calldata _message,
        uint256 _gasLimit,
        address
    ) external payable override  {
        _sendMessage(_to, _value, _message, _gasLimit);
    }

    /// @inheritdoc IL2TwineMessenger
    function relayMessage(
        address _from,
        address _to,
        uint256 _value,
        uint256 _nonce,
        bytes memory _message
    ) external override {
        bytes32 _xDomainCalldataHash = keccak256(_encodeXDomainCalldata(_from, _to, _value, _nonce, _message));

        require(!isL1MessageExecuted[_xDomainCalldataHash], "Message was already successfully executed");

        _executeMessage(_from, _to, _value, _message, _xDomainCalldataHash);
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
    ) internal nonReentrant {
        require(msg.value == _value, "msg.value mismatch");

        uint256 _nonce = L2MessageQueue(messageQueue).nextMessageIndex();
        bytes32 _xDomainCalldataHash = keccak256(_encodeXDomainCalldata(_msgSender(), _to, _value, _nonce, _message));

        L2MessageQueue(messageQueue).appendMessage(_xDomainCalldataHash);

        emit SentMessage(_msgSender(), _to, _value, _nonce, _gasLimit, _message);
    }


    /// @param _xDomainCalldataHash The hash of the message.
    function _executeMessage(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _message,
        bytes32 _xDomainCalldataHash
    ) internal {
        xDomainMessageSender = _from;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _to.call{value: _value}(_message);
        // reset value to refund gas.

        if (success) {
            emit RelayedMessage(_xDomainCalldataHash);
        } else {
            emit FailedRelayedMessage(_xDomainCalldataHash);
        }
    }
}