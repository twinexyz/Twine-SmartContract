// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L1CustomERC20Gateway} from "../src/L1/gateways/L1CustomERC20Gateway.sol";
import {L1ETHGateway} from "../src/L1/gateways/L1ETHGateway.sol";
import {L1GatewayRouter} from "../src/L1/gateways/L1GatewayRouter.sol";
import {L1XERC20Gateway} from "../src/L1/gateways/L1XERC20Gateway.sol";
import {L1MessageQueue} from "../src/L1/rollup/L1MessageQueue.sol";
import {TwineChain} from "../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../src/L1/L1TwineMessenger.sol";

contract DeployL1Contracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Read private key from environment variable

        vm.startBroadcast(deployerPrivateKey); // Start broadcasting transactions

        // Deploying an upgradeable proxy for L1CustomERC20Gateway
        address L1CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1CustomERC20Gateway.initialize,
                (address(0), address(0), address(0))
            ) // Example initial value
        );

        // Deploying an upgradeable proxy for L1ETHGateway
        address L1ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L1ETHGateway.sol",
            msg.sender,
            abi.encodeCall(
                L1ETHGateway.initialize,
                (address(0), address(0), address(0))
            ) // Example initial value
        );

        // Deploying an upgradeable proxy for L1GatewayRouter
        address L1GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L1GatewayRouter.sol",
            msg.sender,
            abi.encodeCall(L1GatewayRouter.initialize, (address(0), address(0))) // Example initial value
        );

        // Deploying an upgradeable proxy for L1XERC20Gateway
        address L1XERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1XERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1XERC20Gateway.initialize,
                (address(0), address(0), address(0))
            ) // Example initial value
        );

        // Deploying an upgradeable proxy for L1MessageQueue
        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol",
            msg.sender,
            abi.encodeCall(L1MessageQueue.initialize, (address(0))) // Example initial value
        );

        // Deploying an upgradeable proxy for TwineChain
        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            msg.sender,
            abi.encodeCall(TwineChain.initialize, (address(0), address(0))) // Example initial value
        );

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (address(0), address(0), address(0))
            ) // Example initial value
        );

        vm.stopBroadcast(); // Stop broadcasting transactions

        // Logging the address of the deployed proxies
        console.log(
            "Contracts deployed at:",
            L1CustomERC20GatewayAddress,
            L1ETHGatewayAddress,
            L1GatewayRouterAddress
        );
        console.log(
            L1XERC20GatewayAddress,
            L1MessageQueueAddress,
            TwineChainAddress,
            L1TwineMessengerAddress
        );
    }
}
