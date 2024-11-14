// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {TwineL2MessengerBase} from "../libraries/messenger/TwineL2MessengerBase.sol";
import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";
contract L2TwineMessenger is TwineL2MessengerBase, IL2TwineMessenger {
    
    /// @notice The address of Consensus Proving Precompile
    address public consensusPrecompileAddress;

    /// @notice The address of bridging Precompile
    address public bridgingPrecompileAddress;

    /// @notice Mapping from L1 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL1MessageExecuted;

    /// @notice Mapping to store the receipt roots for each block number
    mapping(uint256 => mapping(uint256 => bytes32)) public blockReceiptRoots;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _ethChaindId,address _ethCounterpart, address _roleManager)
        external
        initializer
    {
        TwineL2MessengerBase.__TwineMessengerBase_init(_ethChaindId,_ethCounterpart,_roleManager);
    }

    function setPrecompileAddress(address _consensusPrecompileAddress,address _bridgingPrecompileAddress) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        consensusPrecompileAddress = _consensusPrecompileAddress;
        bridgingPrecompileAddress = _bridgingPrecompileAddress;
    }

    /// @inheritdoc ITwineL2MessengerBase
    function sendMessage(
        address _to,
        uint256 _value,
        bytes memory _message,
        uint256 _gasLimit
    ) external payable override {
        _sendMessage(_to, _value, _message, _gasLimit);
    }

    /// @inheritdoc ITwineL2MessengerBase
    function sendMessage(
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
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        (bool success, bytes memory output) = consensusPrecompileAddress.call(consensusData);
        require(success, "Consensus proof Failed!");
        emit consensusVerified(consensusData);
        
    }

    function executeDepositTransactions(
        bytes[] memory depositTransactions,
        bytes memory proof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        bytes memory data = abi.encode(depositTransactions, proof);
        (bool success, bytes memory output) = bridgingPrecompileAddress.call(data);
        require(success, "Deposits failed!");
        emit L1Deposit();
    }

    function executeForcedWithdrawal(
        bytes memory withdrawalTransaction,
        bytes memory proof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        bytes memory data = abi.encode(withdrawalTransaction, proof);
        (bool success, bytes memory output) = bridgingPrecompileAddress.call(data);
        require(success, "Withdrawal failed!");
        emit ForcedWithdrawal();
    }

    /// @dev Internal function to send cross domain message.
    /// @param _to The address of the contract to call.
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
