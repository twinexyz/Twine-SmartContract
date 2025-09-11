// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1MessageHandler} from "../../../src/L1/rollup/L1MessageHandler.sol";

contract ViewRoleManager is Script {
    L1MessageHandler l1MessageHandler;
    address l1MessageHandlerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1MessageHandler"
        );
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Role Manager: ", l1MessageHandler.roleManager());
        vm.stopBroadcast();
    }
}

contract ViewMessagengerAddress is Script {
    L1MessageHandler l1MessageHandler;
    address l1MessageHandlerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1MessageHandler"
        );
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Messenger Address", l1MessageHandler.messenger());
        vm.stopBroadcast();
    }
}

contract ViewMessageHandlerProxy is Script {
    L1MessageHandler l1MessageHandler;
    address l1MessageHandlerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1MessageHandler"
        );
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Message Handler Proxy: ",
            l1MessageHandler.messageHandlerProxy()
        );
        vm.stopBroadcast();
    }
}

contract ViewCurrentMessageNonce is Script {
    L1MessageHandler l1MessageHandler;
    address l1MessageHandlerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1MessageHandler"
        );
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Current Message Nonce: ",
            l1MessageHandler.messageIndex()
        );
        vm.stopBroadcast();
    }
}