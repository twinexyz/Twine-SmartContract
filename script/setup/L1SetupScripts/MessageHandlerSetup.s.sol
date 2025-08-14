// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import {L1MessageHandler} from "../../../src/L1/rollup/L1MessageHandler.sol";

contract SetRoleManager is Script {
    L1MessageHandler l1MessageHandler;
    address l1MessageQueueAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageQueueAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageHandler.setRoleManager(roleManagerAddress);
        vm.stopBroadcast();
    }
}

contract SetChainId is Script {
 L1MessageHandler l1MessageHandler;
    address l1MessageQueueAddress;
    uint64 chainId;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageQueueAddress);

        chainId = uint64(vm.envUint("CHAIN_ID"));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageHandler.setChainId(chainId);
        vm.stopBroadcast();
    }
}

contract SetMessagengerAddress is Script {
 L1MessageHandler l1MessageHandler;
    address l1MessageQueueAddress;
    address messengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageQueueAddress);

        messengerAddress = vm.envAddress("L1_MESSENGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageHandler.setMessengerAddress(messengerAddress);
        vm.stopBroadcast();
    }
}

contract SetMessageQueueProxy is Script {
 L1MessageHandler l1MessageHandler;
    address l1MessageQueueAddress;
    address messageQueueProxy;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageQueueAddress);

        messageQueueProxy = vm.envAddress("MESSAGE_QUEUE_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageHandler.setMessageQueueProxy(messageQueueProxy);
        vm.stopBroadcast();
    }
}
