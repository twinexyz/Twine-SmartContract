// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL1TwineMessenger} from "./IL1TwineMessenger.sol";
import {IL1MessageHandler} from "./rollup/IL1MessageHandler.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {TwineL1MessengerBase} from "../libraries/messenger/TwineL1MessengerBase.sol";
import {ITwineL1MessengerBase} from "../libraries/messenger/ITwineL1MessengerBase.sol";

contract L1TwineMessenger is TwineL1MessengerBase, IL1TwineMessenger {
    /*************
     * Variables *
     *************/

    /// @notice The address of L1MessageHandler contract.
    address public messageHandler;

    /// @notice The address of Rollup contract.
    address public rollup;

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
    /// @param _messageHandler The address of `L1MessageHandler` contract.
    /// @param _rollup The address of rollup contract.
    function initialize(
        address _counterpart,
        address _messageHandler,
        address _rollup,
        address _roleManager
    ) external initializer {
        __TwineMessengerBase_init(_counterpart, _roleManager);

        messageHandler = _messageHandler;
        rollup = _rollup;
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    function setMessageHandlerAddress(
        address _messageHandler
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_messageHandler == address(0)) {
            revert ErrorZeroAddress();
        }
        messageHandler = _messageHandler;
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
        _sendMessage(txnType, from, to, l1Token, l2Token, amount, message);
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
            IL1MessageHandler(messageHandler).appendCrossDomainDepositMessage(
                from,
                to,
                l1Token,
                l2Token,
                amount,
                message
            );
        } else {
            IL1MessageHandler(messageHandler)
                .appendCrossDomainWithdrawalMessage(
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
