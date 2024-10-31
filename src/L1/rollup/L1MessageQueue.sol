// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";

contract L1MessageQueue is ContextUpgradeable, IL1MessageQueue {
    /// @notice The address of L1TwineMessenger contract.
    uint256 chainId;
    uint256 depositMessageIndex;
    uint256 withdrawalMessageIndex;
    address public messenger;
    address public roleManager;

    /// @notice The list of queued cross domain messages.
    bytes[] public depositMessageQueue;

    /// @notice The list of queued cross domain Withdrawal messages.
    bytes[] public withdrawalMessageQueue;


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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // @notice Initialize the storage of L1MessageQueue.
    /// @param _messenger The address of L1TwineMessenger in L1.
    function initialize(address _messenger,uint256 _chainId,address _roleManager) external initializer {
        messenger = _messenger;
        chainId = _chainId;
        roleManager = _roleManager;
    }

    function setAddress(address _messenger) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        messenger = _messenger;
    }

    function setChainId(uint256 _chainId) external  onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()){
        chainId = _chainId;
    }

    function setRoleManager(address _roleManager) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()){
        roleManager = _roleManager;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainDepositMessageIndex() external view returns (uint256) {
        return depositMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainWithdrawalMessageIndex() external view returns (uint256) {
        return withdrawalMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstDepositElement() external {
        require(depositMessageQueue.length > 0, "Array is empty");

        // Shift elements to the left
        for (uint256 i = 0; i < depositMessageQueue.length - 1; i++) {
            depositMessageQueue[i] = depositMessageQueue[i + 1];
        }

        // Remove the last element (since it's now a duplicate of the second-to-last element)
        depositMessageQueue.pop();
    }

    /// @inheritdoc IL1MessageQueue
    function popFirstWithdrawalElement() external {
        require(withdrawalMessageQueue.length > 0, "Array is empty");

        // Shift elements to the left
        for (uint256 i = 0; i < withdrawalMessageQueue.length - 1; i++) {
            withdrawalMessageQueue[i] = withdrawalMessageQueue[i + 1];
        }

        // Remove the last element (since it's now a duplicate of the second-to-last element)
        withdrawalMessageQueue.pop();
    }


    function getCrossDomainDepositMessage(uint256 _queueIndex)
        external
        view
        returns (bytes memory)
    {
        return depositMessageQueue[_queueIndex];
    }

    function getCrossDomainWithdrawalMessage(uint256 _queueIndex)
        external
        view
        returns (bytes memory)
    {
        return withdrawalMessageQueue[_queueIndex];
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainDepositMessage(
        address _target,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external override onlyMessenger {

        address _sender = _msgSender();

        _queueDepositTransaction(_sender,_to,_value, _target, _gasLimit, _data);
    }

    /// @inheritdoc IL1MessageQueue
     function appendCrossDomainWithdrawalMessage(
        address _target,
        address _to,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) external onlyMessenger {
        address _sender = _msgSender();

        _queueWithdrawalTransaction(_sender,_to,_value, _target, _gasLimit, _data);
    }

    /// @dev Internal function to queue a L1 transaction.
    /// @param _sender The address of sender who will initiate this transaction in L2.
    /// @param _value The value passed
     /// @param _target The address of target contract to call in L2.
    /// @param _gasLimit The maximum gas should be used for this transaction in L2.
    /// @param _data The calldata passed to target contract.
    function _queueDepositTransaction(
        address _sender,
        address _to,
        uint256 _value,
        address _target,
        uint256 _gasLimit,
        bytes calldata _data
    ) internal {
        ++ depositMessageIndex ;
        bytes memory depositMessageByteCode = abi.encode(
            _sender,
            _to,
            _value,
            _target,
            depositMessageIndex,
            _gasLimit,
            _data
        );

        depositMessageQueue.push(depositMessageByteCode);

        // emit event
        emit QueueDepositTransaction(
            _sender,
            _to,
            _target,
            _value,
            chainId,
            depositMessageIndex,
            _gasLimit,
            _data
        );
    }

    function _queueWithdrawalTransaction(
        address _sender,
        address _to,
        uint256 _value,
        address _target,
        uint256 _gasLimit,
        bytes calldata _data
    ) internal {

        ++ withdrawalMessageIndex;
        bytes memory withdrawMessageByteCode  = abi.encode(
            _sender,
            _to,
            _target,
            _value,
            withdrawalMessageIndex,
            _gasLimit,
            _data
        );
        withdrawalMessageQueue.push(withdrawMessageByteCode);

        // emit event
        emit QueueWithdrawalTransaction(
            _sender,
            _to,
            _target, 
            _value,
            chainId, 
            withdrawalMessageIndex, 
            _gasLimit, 
            _data
        );
    }


}
