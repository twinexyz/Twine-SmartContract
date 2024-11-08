// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Create2DeployFactory} from "./Create2DeployFactory.sol";

contract DeployCreate2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address admin = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address messageQueue = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        vm.startBroadcast(deployerPrivateKey);

        // Generate a unique salt
        bytes32 salt = keccak256(abi.encodePacked("TwineContract"));

        L2TwineMessenger l2TwineMessengerImplementation = new L2TwineMessenger{
            salt: salt
        }();

        console.log(
            "L2TwineMessenger deployed at :",
            address(l2TwineMessengerImplementation)
        );

        // Prepare initialization data
        bytes memory initializeData = abi.encodeWithSelector(
            L2TwineMessenger.initialize.selector,
            address(0),
            messageQueue
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{
            salt: salt
        }(address(l2TwineMessengerImplementation), admin, initializeData);

        bytes memory bytecode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(
                address(l2TwineMessengerImplementation),
                admin,
                initializeData
            )
        );

        address estimatedAddress = vm.computeCreate2Address(
            salt,
            keccak256(bytecode)
        );

        console.log(
            "Estimated deployed Addres of Proxy contract :",
            estimatedAddress
        );
        console.log(
            "Actual deployed Address of Proxy contract :",
            address(proxy)
        );

        // Verify that the deployed address matches the computed address
        require(address(proxy) == estimatedAddress, "Addresses don't match!");

        vm.stopBroadcast();
    }
}
