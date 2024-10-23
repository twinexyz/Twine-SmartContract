// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L2CustomERC20Gateway} from "../src/L2/gateways/L2CustomERC20Gateway.sol";
import {L2ETHGateway} from "../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../src/L2/gateways/L2GatewayRouter.sol";
import {L2XERC20Gateway} from "../src/L2/gateways/L2XERC20Gateway.sol";
import {L2TwineMessenger} from "../src/L2/L2TwineMessenger.sol";

contract DeployL2Contracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Read private key from environment variable

        vm.startBroadcast(deployerPrivateKey); // Start broadcasting transactions

        // Deploying an upgradeable proxy for L2CustomERC20Gateway
        address L2CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L2CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L2CustomERC20Gateway.initialize,
                (address(0), address(0), address(0))
            ) // Example initial value
        );

        // Deploying an upgradeable proxy for L2ETHGateway
        address L2ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L2ETHGateway.sol",
            msg.sender,
            abi.encodeCall(
                L2ETHGateway.initialize,
                (address(0), address(0), address(0))
            ) // Example initial value
        );

        // Deploying an upgradeable proxy for L2GatewayRouter
        address L2GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L2GatewayRouter.sol",
            msg.sender,
            abi.encodeCall(L2GatewayRouter.initialize, (address(0), address(0))) // Example initial value
        );

        // Deploying an upgradeable proxy for L2XERC20Gateway
        address L2XERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L2XERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L2XERC20Gateway.initialize,
                (address(0), address(0), address(0))
            ) // Example initial value
        );

        // Deploying an upgradeable proxy for L2TwineMessenger
        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (address(0), address(0))
            ) // Example initial value
        );

        vm.stopBroadcast(); // Stop broadcasting transactions

        // Logging the address of the deployed proxies
        console.log(
            "Contracts deployed at:",
            L2CustomERC20GatewayAddress,
            L2ETHGatewayAddress,
            L2GatewayRouterAddress
        );
        console.log(L2XERC20GatewayAddress, L2TwineMessengerAddress);
    }
}
