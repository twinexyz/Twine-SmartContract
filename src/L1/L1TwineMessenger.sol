// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITwineChain} from "./rollup/ITwineChain.sol";
import {IL1TwineMessenger} from "./IL1TwineMessenger.sol";
import {IL1MessageQueue} from "./rollup/IL1MessageQueue.sol";
import {WithdrawTrieVerifier} from "../libraries/verifier/WithdrawTrieVerifier.sol";


contract L1TwineMessenger is IL1TwineMessenger {

    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);
    
    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /// @notice The address of L1MessageQueue contract.
    address public immutable messageQueue;

     /// @notice The address of Rollup contract.
    address public immutable rollup;

    /// @notice The address of counterpart TwineMessenger contract in L1/L2.
    address public immutable counterpart;

    address public xDomainMessageSender;

    
    /// @notice Mapping from L2 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL2MessageExecuted;

    constructor(
        address _counterpart,
        address _rollup,
        address _messageQueue
    ) {
        if(_counterpart == address(0) || _messageQueue == address(0) ) {
            revert ErrorZeroAddress();
        }

        counterpart = _counterpart;
        messageQueue = _messageQueue;
        rollup = _rollup;

    }


    function sendMessage(
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit
    ) external payable override {
        _sendMessage(_to, _value, _message, _gasLimit, msg.sender);
    }

    function sendMessage(
        address _to,
        uint256 _value,
        bytes calldata _message,
        uint256 _gasLimit,
        address _refundAddress
    ) external payable override {
        _sendMessage(_to, _value, _message, _gasLimit, _refundAddress);
    }   

    function relayMessageWithProof(
        address _from,
        address _to,
        uint256 _value,
        uint256 _nonce,
        bytes memory _message,
        L2MessageProof memory _proof
    ) external override {
        bytes32 _xDomainCalldataHash = keccak256(_encodeXDomainCalldata(_from, _to, _value, _nonce, _message));
        require(!isL2MessageExecuted[_xDomainCalldataHash], "Message was already successfully executed");

        {
            require(ITwineChain(rollup).isBatchFinalized(_proof.batchIndex), "Batch is not finalized");
            bytes32 _messageRoot = ITwineChain(rollup).withdrawRoots(_proof.batchIndex);
            require(
                WithdrawTrieVerifier.verifyMerkleProof(_messageRoot, _xDomainCalldataHash, _nonce, _proof.merkleProof),
                "Invalid proof"
            );
        }

        xDomainMessageSender = _from;
        (bool success, ) = _to.call{value: _value}(_message);
    
        if (success) {
            isL2MessageExecuted[_xDomainCalldataHash] = true;
            emit RelayedMessage(_xDomainCalldataHash);
        } else {
            emit FailedRelayedMessage(_xDomainCalldataHash);
        }
    }

     function _sendMessage(
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit,
        address _refundAddress
    ) internal {
        // compute the actual cross domain message calldata.
        uint256 _messageNonce = IL1MessageQueue(messageQueue).nextCrossDomainMessageIndex();
        bytes memory _xDomainCalldata = _encodeXDomainCalldata(msg.sender, _to, _value, _messageNonce, _message);

        // compute and deduct the messaging fee to fee vault.
        //uint256 _fee = IL1MessageQueue(messageQueue).estimateCrossDomainMessageFee(_gasLimit);
        //require(msg.value >= _fee + _value, "Insufficient msg.value");
       // if (_fee > 0) {
       //     (bool _success, ) = feeVault.call{value: _fee}("");
       //     require(_success, "Failed to deduct the fee");
       // }

        // append message to L1MessageQueue
        IL1MessageQueue(messageQueue).appendCrossDomainMessage(counterpart, _gasLimit, _xDomainCalldata);

        // record the message hash for future use.
        //bytes32 _xDomainCalldataHash = keccak256(_xDomainCalldata);

        // normally this won't happen, since each message has different nonce, but just in case.
        //require(messageSendTimestamp[_xDomainCalldataHash] == 0, "Duplicated message");
        //messageSendTimestamp[_xDomainCalldataHash] = block.timestamp;

        emit SentMessage(msg.sender, _to, _value, _messageNonce, _gasLimit, _message);

        // refund fee to `_refundAddress`
        // unchecked {
        //     uint256 _refund = msg.value - _value;
        //     if (_refund > 0) {
        //         (bool _success, ) = _refundAddress.call{value: _refund}("");
        //         require(_success, "Failed to refund the fee");
        //     }
        // }
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
    ) internal pure returns (bytes memory) {
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