// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeCreate2 is Script {
    function run() external {
        address l2TwineMessengerAddress = 0xdb4fB660852e4005D331Cb64F7B85DEfB47D5a86; //replace with l2Twine Messgenr

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        L2TwineMessenger l2TwineMessenger = L2TwineMessenger(
            l2TwineMessengerAddress
        );

        L2TwineMessenger newL2TwineMessenger = new L2TwineMessenger();

        console.log(
            "New Deployed implementation :",
            address(newL2TwineMessenger)
        );

        console.log(
            "Get Admin Address :",
            Upgrades.getAdminAddress(address(l2TwineMessenger))
        );

        address prevImplementationAddress = Upgrades.getImplementationAddress(
            address(l2TwineMessenger)
        );
        console.log("Get previous Implementation :", prevImplementationAddress);

        address proxyAdminContractAddress = Upgrades.getAdminAddress(
            address(l2TwineMessenger)
        );
        ProxyAdmin contractAdmin = ProxyAdmin(proxyAdminContractAddress);

        console.log("Proxy Admin Owner :", contractAdmin.owner());

        contractAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2TwineMessengerAddress),
            address(newL2TwineMessenger),
            ""
        );

        address newImplementationAddress = Upgrades.getImplementationAddress(
            address(l2TwineMessenger)
        );

        console.log("Get Changed Implementation :", newImplementationAddress);

        vm.stopBroadcast();
    }
}
