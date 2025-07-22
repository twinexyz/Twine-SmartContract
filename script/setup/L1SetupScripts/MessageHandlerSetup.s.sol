// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import {L1MessageHandler} from "../../../src/L1/rollup/L1MessageHandler.sol";

contract SetRoleManager is Script {
    L1MessageHandler l1MessageHandler;
    address l1MessageHandlerAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageHandlerAddress = vm.parseJsonAddress(deployedJson, ".L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
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
    address l1MessageHandlerAddress;
    uint64 chainId;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageHandlerAddress = vm.parseJsonAddress(deployedJson, ".L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
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
    address l1MessageHandlerAddress;
    address messengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageHandlerAddress = vm.parseJsonAddress(deployedJson, ".L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
        messengerAddress = vm.envAddress("L1_MESSENGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageHandler.setMessengerAddress(messengerAddress);
        vm.stopBroadcast();
    }
}

contract SetMessageHandlerProxy is Script {
    L1MessageHandler l1MessageHandler;
    address l1MessageHandlerAddress;
    address messageHandlerProxy;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1MessageHandlerAddress = vm.parseJsonAddress(deployedJson, ".L1MessageHandler");
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
        messageHandlerProxy = vm.envAddress("MESSAGE_Handler_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1MessageHandler.setMessageHandlerProxy(messageHandlerProxy);
        vm.stopBroadcast();
    }
}
