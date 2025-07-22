// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";

contract SetRoleManagerAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1TwineMessengerAddress = vm.parseJsonAddress(deployedJson, ".L1TwineMessenger");
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }   

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        l1TwineMessenger.setRoleManager(roleManagerAddress);
        vm.stopBroadcast();
    }
}

contract SetRollupAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address rollupAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1TwineMessengerAddress = vm.parseJsonAddress(deployedJson, ".L1TwineMessenger");
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        rollupAddress = vm.envAddress("ROLLUP_ADDRESS");
    }   

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1TwineMessenger.setRollupAddress(rollupAddress);
        vm.stopBroadcast();
    }
}

contract setMessageQueueAddress is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address messageQueueAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1TwineMessengerAddress = vm.parseJsonAddress(deployedJson, ".L1TwineMessenger");
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        messageQueueAddress = vm.envAddress("MESSAGE_QUEUE_ADDRESS");
    }   

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1TwineMessenger.setMessengerQueueAddress(messageQueueAddress);
        vm.stopBroadcast();
    }
}

contract SetCounterpartMessenger is Script {
    L1TwineMessenger l1TwineMessenger;
    address l1TwineMessengerAddress;
    address counterpartMessenger;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1TwineMessengerAddress = vm.parseJsonAddress(deployedJson, ".L1TwineMessenger");
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        counterpartMessenger = vm.envAddress("COUNTERPART_MESSENGER");
    }   

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1TwineMessenger.setCounterpartMessenger(counterpartMessenger);
        vm.stopBroadcast();
    }
}
