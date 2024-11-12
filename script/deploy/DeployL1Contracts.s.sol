// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {TwineChain} from "../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../src/L1/L1TwineMessenger.sol";
import {L1ETHGateway} from "../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageQueue} from "../../src/L1/rollup/L1MessageQueue.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {L1GatewayRouter} from "../../src/L1/gateways/L1GatewayRouter.sol";
import {L1XERC20Gateway} from "../../src/L1/gateways/L1XERC20Gateway.sol";
import {L1CustomERC20Gateway} from "../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract DeployL1Contracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey); // Start broadcasting transactions

        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );

        // Deploying an upgradeable proxy for L1CustomERC20Gateway
        address L1CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1CustomERC20Gateway.initialize,
                (address(0), address(0), address(0))
            )
        );

        // Deploying an upgradeable proxy for L1ETHGateway
        address L1ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L1ETHGateway.sol",
            msg.sender,
            abi.encodeCall(
                L1ETHGateway.initialize,
                (address(0), address(0), address(0))
            )
        );

        // Deploying an upgradeable proxy for L1GatewayRouter
        address L1GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L1GatewayRouter.sol",
            msg.sender,
            abi.encodeCall(
                L1GatewayRouter.initialize,
                (address(0), address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L1XERC20Gateway
        address L1XERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1XERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1XERC20Gateway.initialize,
                (address(0), address(0), address(0))
            )
        );

        // Deploying an upgradeable proxy for L1MessageQueue
        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol",
            msg.sender,
            abi.encodeCall(
                L1MessageQueue.initialize,
                (0, address(0), address(0))
            )
        );

        // Deploying an upgradeable proxy for TwineChain
        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            msg.sender,
            abi.encodeCall(
                TwineChain.initialize,
                (L1MessageQueueAddress, address(0))
            )
        );

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            msg.sender,
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

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Logging the address of the deployed proxies
        console.log("Deployed Contracts :");
        console.log("L1 Eth contract Address :", L1ETHGatewayAddress);
        console.log("L1 Rolemanager contract Address :", roleManagerAddress);
        console.log("Twine chain contract Address :", TwineChainAddress);
        console.log("L1 Gateway Router contract Address :", L1GatewayRouterAddress);
        console.log("L1 XERC20 contract contract Address :", L1XERC20GatewayAddress);
        console.log("L1 Twine Messenger contract Address :", L1TwineMessengerAddress);
        console.log("Custom L1 ERC20 contract Address :", L1CustomERC20GatewayAddress);
        console.log("Message Queue contract Address :", L1MessageQueueAddress);
    }
}
