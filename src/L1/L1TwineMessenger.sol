// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL1TwineMessenger} from "./IL1TwineMessenger.sol";
import {IL1MessageQueue} from "./rollup/IL1MessageQueue.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {TwineL1MessengerBase} from "../libraries/messenger/TwineL1MessengerBase.sol";
import {ITwineL1MessengerBase} from "../libraries/messenger/ITwineL1MessengerBase.sol";

contract L1TwineMessenger is TwineL1MessengerBase, IL1TwineMessenger {
    /*************
     * Variables *
     *************/

    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

    /// @notice The address of Rollup contract.
    address public rollup;

    //gateway address of eth, can be removed
    //gateway address of eth, can be removed
    address public ethGateway;

    //gateway address of erc20 gateway,can be removed
    //gateway address of erc20 gateway,can be removed
    address public ERC20Gateway;

    /*************
     * Mappings  *
     *************/
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
    function initialize(
        address _counterpart,
        address _messageQueue,
        address _rollup,
        address _roleManager
    ) external initializer {
        __TwineMessengerBase_init(_counterpart, _roleManager);

        messageQueue = _messageQueue;
        rollup = _rollup;
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/
    
    function setMessengerQueueAddress(
        address _messageQueue
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_messageQueue == address(0)) {
            revert ErrorZeroAddress();
        }
        messageQueue = _messageQueue;
    }

    function setRollupAddress(
        address _rollup
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_rollup == address(0)) {
            revert ErrorZeroAddress();
        }
        rollup = _rollup;
    }

    /// @inheritdoc ITwineL1MessengerBase
    function sendMessage(
        TransactionType txnType,
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    )
        external
        payable
        override
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_GATEWAYS())
    {
        _sendMessage(txnType, from, to, l1Token, l2Token,amount,message);
    }

    /**********************
     * Internal Functions *
     **********************/

    function _sendMessage(
        TransactionType txnType,
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) internal {
        // If transaction type is Deposit
        if (txnType == TransactionType.deposit) {
            // append message to L1 depositMessageQueue
            IL1MessageQueue(messageQueue).appendCrossDomainDepositMessage(
                from,
                to,
                l1Token,
                l2Token,
                amount,
                message
            );
        } else {
            // append message to L1 withdrawalMessageQueue
            IL1MessageQueue(messageQueue).appendCrossDomainWithdrawalMessage(
                from,
                to,
                l1Token,
                l2Token,
                amount,
                message
            );
        }
    }
}
