// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {TwineMessengerBase} from "../libraries/TwineMessengerBase.sol";
contract L2TwineMessenger is TwineMessengerBase, IL2TwineMessenger {
    
    /// @notice The address of L2MessageQueue.
    address public messageQueue;

    /// @notice The address of Consensus Proving Precompile
    address public consensusPrecompileAddress;

    /// @notice The address of bridging Precompile
    address public bridgingPrecompileAddress;

    /// @notice Mapping from L1 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL1MessageExecuted;

    /// @notice Mapping to store the receipt roots for each block number
    mapping(uint256 => mapping(uint256 => bytes32)) public blockReceiptRoots;
    
    ///@notice Struct to match the precompile's return type
    struct ConsensusVerificationData {
        uint256 chainId;
        uint256 blockNumber;
        bytes32 receiptRoot;
    }

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

    function setPrecompileAddress(address _consensusPrecompileAddress,address _bridgingPrecompileAddress) external {
        consensusPrecompileAddress = _consensusPrecompileAddress;
        bridgingPrecompileAddress = _bridgingPrecompileAddress;
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
        bytes memory consensusData
    ) public {
        (bool success, bytes memory output) = consensusPrecompileAddress.call(consensusData);
        require(success, "Consensus proof Failed!");
        ConsensusVerificationData[] memory verificationData = abi.decode(output,(ConsensusVerificationData[]));
        // Store the decoded data in the mapping
        for (uint i = 0; i < verificationData.length; i++) {
            blockReceiptRoots[verificationData[i].chainId][verificationData[i].blockNumber] = verificationData[i].receiptRoot;
        }
        emit consensusVerified(consensusData);
        
    }

    function executeDepositTransactions(
        bytes[] memory depositTransactions,
        bytes memory proof
    ) public {
        bytes memory data = abi.encode(depositTransactions, proof);
        (bool success, bytes memory output) = bridgingPrecompileAddress.call(data);
        require(success, "Deposits failed!");
        emit L1Deposit();
    }

    function executeForcedWithdrawal(
        bytes memory withdrawalTransaction,
        bytes memory proof
    ) public {
        bytes memory data = abi.encode(withdrawalTransaction, proof);
        (bool success, bytes memory output) = bridgingPrecompileAddress.call(data);
        require(success, "Withdrawal failed!");
        emit ForcedWithdrawal();
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
