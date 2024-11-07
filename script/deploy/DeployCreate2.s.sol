// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {Create2DeployFactory} from "./Create2DeployFactory.sol";

contract DeployCreate2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address admin = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address messageQueue = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Create2Factory
        Create2DeployFactory factory = new Create2DeployFactory();

        // Deploy the implementation
        L2TwineMessenger l2TwineMessengerImplementation = new L2TwineMessenger();

        // Prepare initialization data
        bytes memory initializeData = abi.encodeWithSelector(
            L2TwineMessenger.initialize.selector,
            address(0),
            messageQueue
        );
        // Generate a unique salt
        bytes32 salt = keccak256(abi.encodePacked("TwineContract"));

        // Compute the future address of the proxy
        address estimatedAddress = factory.computeAddress(
            address(l2TwineMessengerImplementation),
            admin,
            initializeData,
            salt
        );

        // Deploy the proxy using CREATE2
        address deployedAddress = factory.deployProxy(
            address(l2TwineMessengerImplementation),
            admin,
            initializeData,
            salt
        );

        console.log("Estimated deployed Addres", estimatedAddress);
        console.log("Actual deployed Address", deployedAddress);

        // Verify that the deployed address matches the computed address
        require(deployedAddress == estimatedAddress, "Addresses don't match!");

        vm.stopBroadcast();
    }
}
