// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import {L1MessageQueue} from "../../../src/L1/rollup/L1MessageQueue.sol";

contract SetRoleManager is Script {
    L1MessageQueue l1MessageQueue;
    address l1MessageQueueAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".L1MessageQueue");
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageQueue.setRoleManager(roleManagerAddress);
        vm.stopBroadcast();
    }
}

contract SetChainId is Script {
 L1MessageQueue l1MessageQueue;
    address l1MessageQueueAddress;
    uint64 chainId;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".L1MessageQueue");
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        chainId = uint64(vm.envUint("CHAIN_ID"));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageQueue.setChainId(chainId);
        vm.stopBroadcast();
    }
}

contract SetMessagengerAddress is Script {
 L1MessageQueue l1MessageQueue;
    address l1MessageQueueAddress;
    address messengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".L1MessageQueue");
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        messengerAddress = vm.envAddress("L1_MESSENGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageQueue.setMessengerAddress(messengerAddress);
        vm.stopBroadcast();
    }
}

contract SetMessageQueueProxy is Script {
 L1MessageQueue l1MessageQueue;
    address l1MessageQueueAddress;
    address messageQueueProxy;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".L1MessageQueue");
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        messageQueueProxy = vm.envAddress("MESSAGE_QUEUE_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageQueue.setMessageQueueProxy(messageQueueProxy);
        vm.stopBroadcast();
    }
}
