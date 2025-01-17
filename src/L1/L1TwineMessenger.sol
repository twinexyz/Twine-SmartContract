// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineChain} from "./rollup/ITwineChain.sol";
import {IL1TwineMessenger} from "./IL1TwineMessenger.sol";
import {IL1MessageQueue} from "./rollup/IL1MessageQueue.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {IL1ETHGateway} from "./gateways/interfaces/IL1ETHGateway.sol";
import {IL1ERC20Gateway} from "./gateways/interfaces/IL1ERC20Gateway.sol";
import {TwineL1MessengerBase} from "../libraries/messenger/TwineL1MessengerBase.sol";
import {ITwineL1MessengerBase} from "../libraries/messenger/ITwineL1MessengerBase.sol";

contract L1TwineMessenger is TwineL1MessengerBase, IL1TwineMessenger {
    /// @notice Emitted when a cross domain message is relayed successfully.
    /// @param messageHash The hash of the message.
    event RelayedMessage(bytes32 indexed messageHash);

    /// @notice Emitted when a cross domain message is failed to relay.
    /// @param messageHash The hash of the message.
    event FailedRelayedMessage(bytes32 indexed messageHash);

    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

    /// @notice The address of Rollup contract.
    address public rollup;

    /// @notice Mapping from L2 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL2MessageExecuted;

    //gateway address of eth, can be removed
    address public ethGateway;

    //gateway address of erc20 gateway,can be removed
    address public ERC20Gateway;

    event WithdrawalSuccessful(
        address l1Token,
        address l2Token,
        address recipient,
        uint256 amount
    );

    event WithdrawType(address l1Token);

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

    function setMessengerQueueAddress(
        address _messageQueue
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        messageQueue = _messageQueue;
    }

    function setRollupAddress(
        address _rollup
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        rollup = _rollup;
    }

    /// @inheritdoc ITwineL1MessengerBase
    function sendMessage(
        TransactionType _type,
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) external payable override {
        _sendMessage(_type, to, l1Token, l2Token, amount);
    }

    function _sendMessage(
        TransactionType _type,
        string memory to,
        string memory l1Token,
        string memory l2Token,
        string memory amount
    ) internal {
        // If transaction type is Deposit
        if (_type == TransactionType.deposit) {
            // require(msg.value >= _value, "Insufficient msg.value");

            // append message to L1 depositMessageQueue
            IL1MessageQueue(messageQueue).appendCrossDomainDepositMessage(
                to,
                l1Token,
                l2Token,
                amount
            );
        } else {
            // append message to L1 withdrawalMessageQueue
            IL1MessageQueue(messageQueue).appendCrossDomainWithdrawalMessage(
                to,
                l1Token,
                l2Token,
                amount
            );
        }
    }
}
