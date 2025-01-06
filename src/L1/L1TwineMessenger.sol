// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/console.sol";

import {ITwineChain} from "./rollup/ITwineChain.sol";
import {IL1TwineMessenger} from "./IL1TwineMessenger.sol";
import {IL1MessageQueue} from "./rollup/IL1MessageQueue.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
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
        _sendMessage(_type, to, l1Token, l2Token,  amount);
    }

    // function relayWithdrawal(
    //     uint256 _batchNumber,
    //     Types.ReceiptObject memory _receiptObject,
    //     bytes memory _mptKey,
    //     bytes memory _rlpProof
    // ) external {
    //     bytes32 _receiptObjectHash = keccak256(getReceiptObjectRLP(_receiptObject));
    //     require(!isL2MessageExecuted[_receiptObjectHash], "Message was already successfully executed");
    //     require(ITwineChain(rollup).isBatchFinalized(_batchNumber), "Batch is not Finalized");
    //     require(_receiptObject.success == true, "Failed transaction");
    //     // MerklePatriciaProofVerification
    //     bytes memory receiptObjectRLP = _rlpProof.verifyRLPProof(ITwineChain(rollup).getReceiptRoot(_batchNumber), _mptKey);
    //     require(keccak256(receiptObjectRLP) == _receiptObjectHash, "Proof of inclusion failed");
        
    //     // Check if there are any logs in the ReceiptObject
    //     require(_receiptObject.logs.length > 0, "No logs available");
    //     // Fetch the first log
    //       for(uint256 i = 0; i < _receiptObject.logs.length; i++) {
    //         // check if the log was emitted form L2TwineMessenger
    //         if(_receiptObject.logs[i].logAddress == counterpart) {
    //             // Decoding the log data
    //             (, address counterpartGateway, , uint256 _value, , , bytes memory message) = abi.decode(
    //                 _receiptObject.logs[i].data, 
    //                 (address, address, address, uint256, uint256, uint256, bytes)
    //             );
    //             (bool success, ) = counterpartGateway.call{value: _value}(message);

    //             if (success) {
    //                 isL2MessageExecuted[_receiptObjectHash] = true;
    //                 emit RelayedMessage(_receiptObjectHash);
    //             } else {
    //                 emit FailedRelayedMessage(_receiptObjectHash);
    //             }
    //         }
    //     }   
       
    // }  

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
