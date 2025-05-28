// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {L2MsgExecutor} from "../../../src/L2/L2MsgExecutor.sol";
import {L2TwineMessenger} from "../../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../../src/L2/gateways/L2ETHGateway.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {L2GatewayRouter} from "../../../src/L2/gateways/L2GatewayRouter.sol";
import {MockERC20_9Decimals} from "../../../src/test/mocks/MockERC20_9Decimals.sol";
import {TwineStandardERC20} from "../../../src/libraries/token/TwineStandardERC20.sol";
import {L2CustomERC20Gateway} from "../../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract DeployL2Contracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            initialOwner,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );

        // Deploying an upgradeable proxy for L2GatewayRouter
        address L2GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L2GatewayRouter.sol",
            initialOwner,
            abi.encodeCall(
                L2GatewayRouter.initialize,
                (address(0), address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L2CustomERC20Gateway
        address L2CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L2CustomERC20Gateway.sol",
            initialOwner,
            abi.encodeCall(
                L2CustomERC20Gateway.initialize,
                (L2GatewayRouterAddress, address(0), roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L2ETHGateway
        address L2ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L2ETHGateway.sol",
            initialOwner,
            abi.encodeCall(
                L2ETHGateway.initialize,
                (L2GatewayRouterAddress, address(0), roleManagerAddress)
            )
        );

        address L2MessageExecutorAddress = Upgrades.deployTransparentProxy(
            "L2MsgExecutor.sol",
            initialOwner,
            abi.encodeCall(L2MsgExecutor.initialize, (roleManagerAddress))
        );

        // Deploying an upgradeable proxy for L2TwineMessenger
        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            initialOwner,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (0, address(0), roleManagerAddress, L2MessageExecutorAddress)
            )
        );

        address solToken = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            msg.sender,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("TwineSol", "TWS", 9, address(L2TwineMessengerAddress))
            )
        );
        address ethToken = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            msg.sender,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("TwineEth", "TWE", 18, address(L2TwineMessengerAddress))
            )
        );
        address randomToken = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            msg.sender,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("FauxCoin", "FAUX", 18, address(L2TwineMessengerAddress))
            )
        );

        string memory twineObject = "TwineContracts";
        vm.serializeAddress(twineObject, "SolToken", solToken);
        vm.serializeAddress(twineObject, "ETHToken", ethToken);
        vm.serializeAddress(twineObject, "FauxCoin", randomToken);
        vm.serializeAddress(twineObject, "L2RoleManager", roleManagerAddress);
        vm.serializeAddress(twineObject, "L2ETHGateway", L2ETHGatewayAddress);
        vm.serializeAddress(
            twineObject,
            "L2GatewayRouter",
            L2GatewayRouterAddress
        );
        vm.serializeAddress(
            twineObject,
            "L2MsgExecutor",
            L2MessageExecutorAddress
        );
        vm.serializeAddress(twineObject, "L2XERC20Gateway", address(0));
        vm.serializeAddress(
            twineObject,
            "L2TwineMessenger",
            L2TwineMessengerAddress
        );
        string memory finalJson = vm.serializeAddress(
            twineObject,
            "L2CustomERC20Gateway",
            L2CustomERC20GatewayAddress
        );

        vm.writeJson(finalJson, "./script/utils/twineAddresses.json");

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Logging the address of the deployed proxies
        console.log("Deployed Contracts :");
        console.log("L2 SolToken:", address(solToken));
        console.log("L2 EthToken:", address(ethToken));
        console.log("L2 RandomToken", address(randomToken));
        console.log("L2 Rolemanager :", roleManagerAddress);
        console.log("L2 Eth Gateway :", L2ETHGatewayAddress);
        console.log("L2 Gateway Router :", L2GatewayRouterAddress);
        console.log("L2 Twine Messenger :", L2TwineMessengerAddress);
        console.log("L2 Message Executor  :", L2MessageExecutorAddress);
        console.log("L2 Custom ERC20 Gateway :", L2CustomERC20GatewayAddress);
    }
}
