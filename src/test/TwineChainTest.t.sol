// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {TwineChain} from "../L1/rollup/TwineChain.sol";
import {L1MessageQueue} from "../L1/rollup/L1MessageQueue.sol";
import "../L1/rollup/ITwineChain.sol";
import "../libraries/rlp/Types.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract TwineChainTest is Test {
    TwineChain public twineChain;
    L1MessageQueue public messageQueue;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;

    function setUp() public {
        vm.startPrank(initialOwner);

        // setup L1MessageQueue
        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol", 
            msg.sender,
            abi.encodeCall(L1MessageQueue.initialize, (0,address(0),address(0)))
        );

        messageQueue = L1MessageQueue(L1MessageQueueAddress);

        // setup TwineChain
        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol", 
            msg.sender, 
            abi.encodeCall(TwineChain.initialize, (address(messageQueue), address(0)))
        );

        twineChain = TwineChain(TwineChainAddress);
    } 

    function testChainId() public {
        assertEq(twineChain.chainId(), 0);
        assertEq(twineChain.lastCommittedBatchNumber(), 0);
    }

    function testCommitBatch() public {
        bytes32 bytes32dummy = bytes32(0);
        bytes32[] memory bytes32Array = new bytes32[](1);
        bytes32Array[0] = bytes32dummy;
    
        // Default Access List
        ITwineChain.AccessList memory defaultAccessList = ITwineChain.AccessList({
            _address: address(0),
            storageKeys: bytes32Array
        });

        // Array of Access List
        ITwineChain.AccessList[] memory accessListArray = new ITwineChain.AccessList[](1);
        accessListArray[0] = defaultAccessList;

        // Dummy data for Log data
        bytes memory _message = abi.encode(address(0), address(0), 10);
        bytes memory _data = abi.encode(address(0), address(0), address(0), 0, 3, 0, 0, _message);

        // Dummy Log Data Object
        Types.LogData memory DummyLogData = Types.LogData({
            logAddress: address(0),
            topics: bytes32Array,
            data: _data
        });

        Types.LogData[] memory DummyLogDataArray = new Types.LogData[](1);
        DummyLogDataArray[0] = DummyLogData;

        // Dummy Receipt Object
        Types.TxType types = Types.TxType.Deposit;
        Types.ReceiptObject memory receiptObject = Types.ReceiptObject({
            txType: types,
            success: true,
            cumulativeGasUsed: 0,
            bloom: "",
            logs: DummyLogDataArray
        });

        bytes memory _input = abi.encode(receiptObject);

        // Dummy Transaction Object
        ITwineChain.TransactionObject memory defaultTransactionObject = ITwineChain.TransactionObject({
            transactionHash: bytes32(0),
            nonce: 0,
            blockHash: bytes32(0),
            blockNumber: 0,
            transactionIndex: 0,
            from: address(0),
            to: address(0),
            value: 0,
            gasprice: 0,
            gas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            input: _input,
            r: bytes32(0),
            s: bytes32(0),
            v: 0,
            yParity: 0,
            chainId: 0,
            accesslist: accessListArray,
            TransactionType: 0
        });

        Types.ReceiptObject[] memory receiptObjectArray = new Types.ReceiptObject[](1);
        receiptObjectArray[0] = receiptObject;

        bytes memory depositInput = abi.encode(receiptObjectArray);

        ITwineChain.TransactionObject memory depositTransactionObject = ITwineChain.TransactionObject({
            transactionHash: bytes32(0),
            nonce: 0,
            blockHash: bytes32(0),
            blockNumber: 0,
            transactionIndex: 0,
            from: address(0),
            to: address(0),
            value: 0,
            gasprice: 0,
            gas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            input: depositInput,
            r: bytes32(0),
            s: bytes32(0),
            v: 0,
            yParity: 0,
            chainId: 0,
            accesslist: accessListArray,
            TransactionType: 0
        });

        // Array of dummy Transaction Object
        ITwineChain.TransactionObject[] memory defaultTransactionObjectArray = new ITwineChain.TransactionObject[](1);
        defaultTransactionObjectArray[0] = defaultTransactionObject;

        // Array of dummy deposit Transaction object
        ITwineChain.TransactionObject[] memory depositTransactionObjectArray = new ITwineChain.TransactionObject[](1);
        depositTransactionObjectArray[0] = depositTransactionObject;

        // Dummy CommitBatchInfo
        ITwineChain.CommitBatchInfo memory commitInfo = ITwineChain.CommitBatchInfo({
            batchNumber: 1,
            batchHash: bytes32(0),
            stateRoot: bytes32(0),
            transactionRoot: bytes32(0),
            receiptRoot: bytes32(0),
            depositTransactionObject: depositTransactionObjectArray,
            forcedTransactionObjects: defaultTransactionObjectArray,
            otherTransactions: defaultTransactionObjectArray
        });

        vm.startPrank(initialOwner);

        twineChain.commitBatch(commitInfo);
        assertEq(twineChain.lastCommittedBatchNumber(), 1);
    }
}