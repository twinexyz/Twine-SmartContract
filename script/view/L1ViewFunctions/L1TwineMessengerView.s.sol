// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";

contract ViewRoleManagerAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Role Manager Address: ", l1TwineMessenger.roleManager());
        vm.stopBroadcast();
    }
}

contract ViewRollupAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Rollup Address: ", l1TwineMessenger.rollup());
        vm.stopBroadcast();
    }
}

contract ViewMessageHandlerAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Message Handler Address: ",
            l1TwineMessenger.messageHandler()
        );
        vm.stopBroadcast();
    }
}

contract ViewCounterpartMessenger is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "CounterPart Messenger: ",
            l1TwineMessenger.counterpart()
        );
        vm.stopBroadcast();
    }
}

contract ViewFeeValut is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Fee Vault : ", l1TwineMessenger.feeVault());
        vm.stopBroadcast();
    }
}
