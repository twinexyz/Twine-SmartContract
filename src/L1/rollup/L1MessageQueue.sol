// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IL1MessageQueue} from "./IL1MessageQueue.sol";

contract L1MessageQueue is ContextUpgradeable, IL1MessageQueue {
    /// @notice The address of L1TwineMessenger contract.
    address public messenger;

    /// @notice The list of queued cross domain messages.
    bytes32[] public depositMessageQueue;

    /// @notice The list of queued cross domain Withdrawal messages.
    bytes32[] public withdrawalMessageQueue;


    modifier onlyMessenger() {
        require(
            _msgSender() == messenger,
            "Only callable by the L1TwineMessenger"
        );
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
    function initialize(address _messenger) external initializer {
        messenger = _messenger;
    }

    function setAddress(address _messenger) external {
        messenger = _messenger;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainDepositMessageIndex() external view returns (uint256) {
        return depositMessageQueue.length;
    }

    /// @inheritdoc IL1MessageQueue
    function nextCrossDomainWithdrawalMessageIndex() external view returns (uint256) {
        return withdrawalMessageQueue.length;
    }

    function getCrossDomainDepositMessage(uint256 _queueIndex)
        external
        view
        returns (bytes32)
    {
        return depositMessageQueue[_queueIndex];
    }

    function getCrossDomainWithdrawalMessage(uint256 _queueIndex)
        external
        view
        returns (bytes32)
    {
        return withdrawalMessageQueue[_queueIndex];
    }

    function computeTransactionHash(
        address _sender,
        address _target,
        uint256 _value,
        uint256 _queueIndex,
        uint256 _gasLimit,
        bytes calldata _data
    ) public pure override returns (bytes32) {
        
        return keccak256(abi.encodePacked(_sender, _target, _value, _queueIndex, _gasLimit, _data));
    }

    /// @inheritdoc IL1MessageQueue
    function appendCrossDomainDepositMessage(
        address _target,
        uint256 _gasLimit,
        bytes calldata _data
    ) external override onlyMessenger {
        // validate gas limit
        // _validateGasLimit(_gasLimit, _data);

        // do address alias to avoid replay attack in L2.
        address _sender = _msgSender();

        _queueDepositTransaction(_sender, _target, 0, _gasLimit, _data);
    }

    /// @inheritdoc IL1MessageQueue
     function appendCrossDomainWithdrawalMessage(
        address _target,
        uint256 _gasLimit,
        bytes calldata _data
    ) external onlyMessenger {
        address _sender = _msgSender();

        _queueWithdrawalTransaction(_sender, _target, 0, _gasLimit, _data);
    }

    /// @dev Internal function to queue a L1 transaction.
    /// @param _sender The address of sender who will initiate this transaction in L2.
    /// @param _target The address of target contract to call in L2.
    /// @param _value The value passed
    /// @param _gasLimit The maximum gas should be used for this transaction in L2.
    /// @param _data The calldata passed to target contract.
    function _queueDepositTransaction(
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _data
    ) internal {
        // compute transaction hash
        uint256 _queueIndex = depositMessageQueue.length;
        bytes32 _hash = computeTransactionHash(
            _sender,
            _target,
            _value,
            _queueIndex,
            _gasLimit,
            _data
        );
        depositMessageQueue.push(_hash);

        // emit event
        emit QueueDepositTransaction(
            _sender,
            _target,
            _value,
            uint64(_queueIndex),
            _gasLimit,
            _data
        );
    }

    function _queueWithdrawalTransaction(
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,   
        bytes calldata _data
    ) internal {
        // compute transaction hash
        uint256 _queueIndex = withdrawalMessageQueue.length;
        bytes32 _hash = computeTransactionHash(
            _sender, 
            _target, 
            _value, 
            _queueIndex, 
            _gasLimit, 
            _data
        );
        withdrawalMessageQueue.push(_hash);

        // emit event
        emit QueueWithdrawalTransaction(
            _sender,
            _target, 
            _value, 
            uint64(_queueIndex), 
            _gasLimit, 
            _data
        );
    }


}
