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

    //gateway address of eth
    address public ethGateway;

    //gateway address of erc20 gateway
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
    
    function setGatewayAddress(
        address _ethGateway,
        address _ERC20Gateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        ethGateway = _ethGateway;
        ERC20Gateway = _ERC20Gateway;
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

    function relayWithdrawal(uint256 msgIndex) external {
        require(
            msgIndex <
                IL1MessageQueue(messageQueue)
                    .nextCrossDomainExecutionMessageIndex(),
            "Invalid message index"
        );
        
        IL1MessageQueue.MessageData memory message = IL1MessageQueue(
            messageQueue
        ).getExecutionMessage(msgIndex);
        // Process the message
        address l1Token = stringToAddress(message.l1Token);
        address l2Token = stringToAddress(message.l2Token);
        address recipient = stringToAddress(message.toAddress);
        uint256 amount = stringToUint(message.amount);

        emit WithdrawType(l1Token);
        // // Remove the executed message from the queue
        // IL1MessageQueue(messageQueue).removeExecutionMessage(msgIndex);
        // emit WithdrawalSuccessful(l1Token, l2Token, recipient, amount);
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

    function stringToAddress(
        string memory _addressString
    ) public pure returns (address) {
        bytes memory stringBytes = bytes(_addressString);
        require(
            stringBytes.length == 42 &&
                stringBytes[0] == "0" &&
                stringBytes[1] == "x",
            "Invalid address format"
        );

        uint160 result = 0;
        for (uint i = 2; i < 42; i++) {
            result *= 16;
            uint8 digit = uint8(stringBytes[i]);
            if (digit >= 48 && digit <= 57) {
                result += (digit - 48);
            } else if (digit >= 65 && digit <= 70) {
                result += (digit - 55);
            } else if (digit >= 97 && digit <= 102) {
                result += (digit - 87);
            } else {
                revert("Invalid character in address string");
            }
        }
        return address(result);
    }

    function stringToUint(
        string memory s
    ) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 oldResult = 0;
        for (uint256 i = 0; i < b.length; i++) {
            // c = b[i] was not needed
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                // store old value so we can check for overflows
                oldResult = result;
                result = result * 10 + (uint8(b[i]) - 48);
                if (oldResult > result) {
                    // we can only get here if the result overflowed and is smaller than last stored value
                    revert("Invalid String");
                }
            } else {
                revert("InvalidStringNumber");
            }
        }
    }
}
