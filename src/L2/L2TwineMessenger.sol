// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {TwineMessengerBase} from "../libraries/TwineMessengerBase.sol";

contract L2TwineMessenger is TwineMessengerBase,IL2TwineMessenger {
    
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
    ) internal {
        require(msg.value == _value, "msg.value mismatch");

        emit SentMessage(_msgSender(), _to, _value, _gasLimit, _message);
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

    /// @dev Internal function to generate the correct cross domain calldata for a message.
    /// @param _sender Message sender address.
    /// @param _target Target contract address.
    /// @param _value The amount of ETH pass to the target.
    /// @param _messageNonce Nonce for the provided message.
    /// @param _message Message to send to the target.
    /// @return ABI encoded cross domain calldata.
    function _encodeXDomainCalldata(
        address _sender,
        address _target,
        uint256 _value,
        uint256 _messageNonce,
        bytes memory _message
    ) internal pure 
    
returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(address,address,uint256,uint256,bytes)",
                _sender,
                _target,
                _value,
                _messageNonce,
                _message
            );
    }
}