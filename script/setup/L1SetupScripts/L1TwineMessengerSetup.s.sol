// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";

contract SetRoleManagerAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Previous Role Manager Address",
            l1TwineMessenger.roleManager()
        );

        l1TwineMessenger.setRoleManager(roleManagerAddress);

        console.log("New Role Manager Address", l1TwineMessenger.roleManager());
        vm.stopBroadcast();
    }
}

contract SetRollupAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address rollupAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        rollupAddress = vm.envAddress("ROLLUP_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous RollupAddress: ", l1TwineMessenger.rollup());

        l1TwineMessenger.setRollupAddress(rollupAddress);

        console.log("New RollupAddress: ", l1TwineMessenger.rollup());
        vm.stopBroadcast();
    }
}

contract setMessageHandlerAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address messageHandlerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        messageHandlerAddress = vm.envAddress("MESSAGE_QUEUE_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Previous Message Handler Address",
            l1TwineMessenger.messageHandler()
        );

        l1TwineMessenger.setMessageHandlerAddress(messageHandlerAddress);

        console.log(
            "New Message Handler Address",
            l1TwineMessenger.messageHandler()
        );
        vm.stopBroadcast();
    }
}

contract SetCounterpartMessenger is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address counterpartMessenger;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        counterpartMessenger = vm.envAddress("COUNTERPART_MESSENGER");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Previous CounterPart Messenger: ",
            l1TwineMessenger.counterpart()
        );

        l1TwineMessenger.setCounterpartMessenger(counterpartMessenger);

        console.log(
            "New CounterPart Messenger: ",
            l1TwineMessenger.counterpart()
        );
        vm.stopBroadcast();
    }
}

contract SetFeeValut is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;

    address feeVaultAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        feeVaultAddress = vm.envAddress("FEE_VAULT");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous FeeVault : ", l1TwineMessenger.feeVault());

        l1TwineMessenger.setFeeVault(feeVaultAddress);

        console.log("New FeeVault : ", l1TwineMessenger.feeVault());
        vm.stopBroadcast();
    }
}
