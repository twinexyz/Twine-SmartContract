// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {ITwineChain} from "./rollup/ITwineChain.sol";
import {IL1TwineMessenger} from "./IL1TwineMessenger.sol";
import {IL1MessageQueue} from "./rollup/IL1MessageQueue.sol";
import {ITwineMessenger} from "../libraries/ITwineMessenger.sol";
import {TwineMessengerBase} from "../libraries/TwineMessengerBase.sol";
import {MerklePatriciaProofVerifier} from "../libraries/mpt/MerklePatriciaProofVerifier.sol";
import {RLPEncodeStruct, Types} from "../libraries/rlp/RLPEncodeStruct.sol";

contract L1TwineMessenger is TwineMessengerBase, IL1TwineMessenger {
    using MerklePatriciaProofVerifier for bytes;
    using RLPEncodeStruct for Types.ReceiptObject;

    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain Deposit message is sent.
    /// @param sender The address of the sender who initiates the message.
    /// @param target The address of target contract to call.
    /// @param value The amount of value passed to the target contract.
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    /// @param message The calldata passed to the target contract.
    event SentDepositMessage(
        address indexed sender,
        address indexed target,
        uint256 value,
        uint256 messageNonce,
        uint256 gasLimit,
        bytes message
    );

    /// @notice Emitted when a cross domain withdrawal message is sent.
    /// @param sender The address of the sender who initiates the message.
    /// @param target The address of target contract to call.
    /// @param value The amount of value passed to the target contract.
    /// @param gasLimit The optional gas limit passed to L1 or L2.
    /// @param message The calldata passed to the target contract.
    event SentWithdrawalMessage(
        address indexed sender,
        address indexed target,
        uint256 value,
        uint256 messageNonce,
        uint256 gasLimit,
        bytes message
    );

    /// @notice The address of L1MessageQueue contract.
    address public  messageQueue;

     /// @notice The address of Rollup contract.
    address public  rollup;

    
    /// @notice Mapping from L2 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL2MessageExecuted;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1TwineMessenger.
    /// @param _counterpart The address of L2TwineMessenger in L2.
    /// @param _messageQueue The address of `L1MessageQueue` contract.
    /// @param _rollup The address of rollup contract.
    function initialize(address _counterpart, address _messageQueue, address _rollup)
        external
        initializer
    {
        __TwineMessengerBase_init(_counterpart);
   
        messageQueue = _messageQueue;
        rollup = _rollup;
    }

    function setAddressMessenger(address _messageQueue, address _rollup) external {
        messageQueue = _messageQueue;
        rollup = _rollup;
    }

    /// @inheritdoc ITwineMessenger
    function sendMessage(
        TransactionType _type,
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit
    ) external payable override {
        _sendMessage(_type, _to, _value, _message, _gasLimit, _msgSender());
    }

    function sendMessage(
        TransactionType _type,
        address _to,
        uint256 _value,
        bytes calldata _message,
        uint256 _gasLimit,
        address _refundAddress
    ) external payable override {
        _sendMessage(_type, _to, _value, _message, _gasLimit, _refundAddress);
    }   

    function relayWithdrawal(
        uint256 _batchNumber,
        Types.ReceiptObject memory _receiptObject,
        bytes32 _mptKey,
        bytes memory _rlpProof
    ) external {
        bytes32 _receiptObjectHash = keccak256(_receiptObject.encodeReceiptObject());
        require(!isL2MessageExecuted[_receiptObjectHash], "Message was already successfully executed");
        require(ITwineChain(rollup).isBatchFinalized(_batchNumber), "Batch is not Finalized");
        require(_receiptObject.receipt.success == true, "Failed transaction");
        // MerklePatriciaProofVerification
        bytes memory receiptObjectRLP = _rlpProof.verifyRLPProof(ITwineChain(rollup).getReceiptRoot(_batchNumber), _mptKey);
        require(keccak256(receiptObjectRLP) == _receiptObjectHash, "Proof of inclusion failed");
        
        // Check if there are any logs in the ReceiptObject
        require(_receiptObject.receipt.logs.length > 0, "No logs available");
        // Fetch the first log
        // Decoding the log data using abi.decode
        (, address to, uint256 amount,, bytes memory message) = abi.decode(_receiptObject.receipt.logs[0].logData.data, (address, address, uint256, uint256, bytes));
        (bool success, ) = to.call{value: amount}(message);
        
        if(success) {
            isL2MessageExecuted[_receiptObjectHash] = true;
            emit RelayedMessage(_receiptObjectHash);
        } else {
            emit FailedRelayedMessage(_receiptObjectHash);
        }
    }

    function _sendMessage(
        TransactionType _type,
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit,
        address _from
    ) internal {

        // If transaction type is Deposit
        if(_type == TransactionType.deposit) {
            require(msg.value >= _value, "Insufficient msg.value");

            // compute the actual cross domain message calldata.
            uint256 _messageNonce = IL1MessageQueue(messageQueue).nextCrossDomainDepositMessageIndex();

            // append message to L1 depositMessageQueue
            IL1MessageQueue(messageQueue).appendCrossDomainDepositMessage(counterpart,_to,_value, _gasLimit, _message);

            emit SentDepositMessage(_msgSender(), _to, _value, _messageNonce, _gasLimit, _message);
        }
        else {
                        
            uint256 _messageNonce = IL1MessageQueue(messageQueue).nextCrossDomainWithdrawalMessageIndex();

            // append message to L1 withdrawalMessageQueue
            IL1MessageQueue(messageQueue).appendCrossDomainWithdrawalMessage(counterpart,_to,_value, _gasLimit, _message);

            emit SentWithdrawalMessage(_msgSender(), _to, _value, _messageNonce, _gasLimit, _message);
        }
    }

}   
