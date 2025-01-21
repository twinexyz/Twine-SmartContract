// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";

import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";
import {L1MessageQueue} from "../../../src/L1/rollup/L1MessageQueue.sol";

import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";
import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";
import {L1CustomERC20Gateway} from "../../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract DeployL1Contracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        MockERC20 randomToken = new MockERC20("TwineRandom","TWR");

        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            initialOwner,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );

        // Deploying an upgradeable proxy for L1CustomERC20Gateway
        address L1CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1CustomERC20Gateway.sol",
            initialOwner,
            abi.encodeCall(
                L1CustomERC20Gateway.initialize,
                (address(0), address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L1ETHGateway
        address L1ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L1ETHGateway.sol",
            initialOwner,
            abi.encodeCall(
                L1ETHGateway.initialize,
                (address(0), address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L1GatewayRouter
        address L1GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L1GatewayRouter.sol",
            initialOwner,
            abi.encodeCall(
                L1GatewayRouter.initialize,
                (address(0), address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L1MessageQueue
        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol",
            initialOwner,
            abi.encodeCall(
                L1MessageQueue.initialize,
                (0, address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for TwineChain
        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            initialOwner,
            abi.encodeCall(
                TwineChain.initialize,
                (L1MessageQueueAddress, address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            initialOwner,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (
                    address(0),
                    L1MessageQueueAddress,
                    TwineChainAddress,
                    roleManagerAddress
                )
            )
        );

        string memory twineObject = "l1-contracts";
        vm.serializeAddress(twineObject, "TwineChain", TwineChainAddress);
        vm.serializeAddress(twineObject, "L1ETHGateway", L1ETHGatewayAddress);
        vm.serializeAddress(twineObject, "L1RoleManager",roleManagerAddress );
        vm.serializeAddress(twineObject, "L1MessageQueue", L1MessageQueueAddress);
        vm.serializeAddress(twineObject, "L1GatewayRouter", L1GatewayRouterAddress);
        vm.serializeAddress(twineObject, "L1TwineMessenger", L1TwineMessengerAddress);
        vm.serializeAddress(twineObject, "L1CustomERC20Gateway", L1CustomERC20GatewayAddress);
        vm.serializeAddress(twineObject, "L1XERC20Gateway", address(0));
        vm.serializeAddress(twineObject, "Verifier", address(0));
        vm.serializeAddress(twineObject, "FauxCoin", address(randomToken));

        // Fill them manually
        vm.serializeString(twineObject, "executionVkey", "");
        vm.serializeString(twineObject, "inclusionVkey", "");
        string memory finalJson = vm.serializeString(twineObject, "withdrawalVkey", "");

        vm.writeJson(
            finalJson,
            "./script/utils/L1Addresses.json"
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Logging the address of the deployed proxies
        console.log("Deployed Contracts :");

        console.log("Twine chain :", TwineChainAddress);
        console.log("L1 Eth Gatway :", L1ETHGatewayAddress);
        console.log("L1 Rolemanager :", roleManagerAddress);
        console.log("L1 Message Queue :", L1MessageQueueAddress);
        console.log("L1 Gateway Router :", L1GatewayRouterAddress);
        console.log("L1 Twine Messenger :", L1TwineMessengerAddress);
        console.log("L1 Custom ERC20 Gateway:", L1CustomERC20GatewayAddress);
    }
}
