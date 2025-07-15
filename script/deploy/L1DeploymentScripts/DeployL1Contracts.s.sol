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

import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";

contract DeployL1Contracts is Script {

    struct DeployedContracts {
        address roleManager;
        address twineChain;
        address l1ETHGateway;
        address l1GatewayRouter;
        address l1MessageQueue;
        address l1TwineMessenger;
        address l1CustomERC20Gateway;
        address verifier;
        address fauxCoin;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory defaultAddressPath = "./script/utils/L1Addresses.json";
        string memory exportPath = vm.envOr(
            "ADDRESSES_EXPORT_PATH",
            defaultAddressPath
        );
        address initialOwner = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        DeployedContracts memory contracts;

        // Deploy MockERC20
        contracts.fauxCoin = address(new MockERC20("FauxCoin", "FAUX"));

        // Deploying an upgradable proxy for RoleManager
        contracts.roleManager = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            initialOwner,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );

        // Deploying an upgradeable proxy for L1CustomERC20Gateway
        contracts.l1CustomERC20Gateway = Upgrades.deployTransparentProxy(
            "L1CustomERC20Gateway.sol",
            initialOwner,
            abi.encodeCall(
                L1CustomERC20Gateway.initialize,
                (address(0), address(0), contracts.roleManager, 0)
            )
        );

        // Deploying an upgradeable proxy for L1ETHGateway
        contracts.l1ETHGateway = Upgrades.deployTransparentProxy(
            "L1ETHGateway.sol",
            initialOwner,
            abi.encodeCall(
                L1ETHGateway.initialize,
                (address(0), address(0), contracts.roleManager, 0)
            )
        );

        // Deploying an upgradeable proxy for L1GatewayRouter
        contracts.l1GatewayRouter = Upgrades.deployTransparentProxy(
            "L1GatewayRouter.sol",
            initialOwner,
            abi.encodeCall(
                L1GatewayRouter.initialize,
                (address(0), address(0), contracts.roleManager)
            )
        );

        // Deploying an upgradeable proxy for L1MessageQueue
        contracts.l1MessageQueue = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol",
            initialOwner,
            abi.encodeCall(
                L1MessageQueue.initialize,
                (0, address(0), contracts.roleManager)
            )
        );

        // Deploying an upgradeable proxy for TwineChain
        contracts.twineChain = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            initialOwner,
            abi.encodeCall(
                TwineChain.initialize,
                (contracts.l1MessageQueue, address(0), contracts.roleManager)
            )
        );

        // Deploying an upgradeable proxy for L1TwineMessenger
        contracts.l1TwineMessenger = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            initialOwner,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (
                    address(0),
                    contracts.l1MessageQueue,
                    contracts.twineChain,
                    contracts.roleManager
                )
            )
        );

        // Deploying the SP1Verifier contract
        contracts.verifier = address(new SP1Verifier());

        string memory twineObject = "l1-contracts";
        vm.serializeAddress(twineObject, "TwineChain", contracts.twineChain);
        vm.serializeAddress(twineObject, "L1ETHGateway", contracts.l1ETHGateway);
        vm.serializeAddress(twineObject, "L1RoleManager", contracts.roleManager);
        vm.serializeAddress(twineObject, "L1MessageQueue", contracts.l1MessageQueue);
        vm.serializeAddress(twineObject, "L1GatewayRouter", contracts.l1GatewayRouter);
        vm.serializeAddress(twineObject, "L1TwineMessenger", contracts.l1TwineMessenger);
        vm.serializeAddress(twineObject, "L1CustomERC20Gateway", contracts.l1CustomERC20Gateway);
        vm.serializeAddress(twineObject, "L1XERC20Gateway", address(0));
        vm.serializeAddress(twineObject, "Verifier", contracts.verifier);
        vm.serializeAddress(twineObject, "FauxCoin", contracts.fauxCoin);

        // Fill them manually
        vm.serializeString(twineObject, "executionVkey", "");
        vm.serializeString(twineObject, "inclusionVkey", "");
        string memory finalJson = vm.serializeString(
            twineObject, 
            "withdrawalVkey", 
            ""
        ); // Capture the final serialized string

        vm.writeJson(finalJson, exportPath);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Logging the address of the deployed proxies
        console.log("Deployed Contracts :");

        console.log("Twine chain :", contracts.twineChain);
        console.log("L1 Eth Gatway :", contracts.l1ETHGateway);
        console.log("L1 Rolemanager :", contracts.roleManager);
        console.log("L1 Message Queue :", contracts.l1MessageQueue);
        console.log("L1 Gateway Router :", contracts.l1GatewayRouter);
        console.log("L1 Twine Messenger :", contracts.l1TwineMessenger);
        console.log("L1 Custom ERC20 Gateway:", contracts.l1CustomERC20Gateway);
        console.log("SP1 Verifier:", contracts.verifier);
    }
}
