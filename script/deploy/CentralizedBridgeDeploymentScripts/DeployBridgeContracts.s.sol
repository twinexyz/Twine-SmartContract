// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {L1ERC20} from "../../../src/libraries/token/L1ERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {CentralizedTwineMessenger} from "../../../src/centralizedBridge/CentralizedTwineMessenger.sol";
import {CentralizedETHGateway} from "../../../src/centralizedBridge/centralizedGateways/CentralizedETHGateway.sol";
import {CentralizedGatewayRouter} from "../../../src/centralizedBridge/centralizedGateways/CentralizedGatewayRouter.sol";
import {CentralizedCustomERC20Gateway} from "../../../src/centralizedBridge/centralizedGateways/CentralizedCustomERC20Gateway.sol";

contract DeployBridgeContracts is Script {
    struct DeployedContracts {
        address roleManager;
        address centralizedEthGateway;
        address centralizedGatewayRouter;
        address centralizedTwineMessenger;
        address centralizedCustomErc20Gateway;
        address fauxCoin;
        address solToken;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");
        string memory defaultAddressPath = "./script/utils/CentralizeBridgeAddresses.json";
        string memory exportPath = vm.envOr(
            "ADDRESSES_EXPORT_PATH",
            defaultAddressPath
        );
        address initialOwner = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        DeployedContracts memory contracts;

        // Deploying an upgradable proxy for RoleManager
        contracts.roleManager = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            initialOwner,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );

        // Deploy fauxcoin
        contracts.fauxCoin = Upgrades.deployTransparentProxy(
            "L1ERC20.sol",
            initialOwner,
            abi.encodeCall(
                L1ERC20.initialize,
                ("FauxCoin", "FAUX", 18, address(contracts.roleManager))
            )
        );

        // Deploy solToken
        contracts.solToken = Upgrades.deployTransparentProxy(
            "L1ERC20.sol",
            initialOwner,
            abi.encodeCall(
                L1ERC20.initialize,
                ("EthSol", "ESol", 9, address(contracts.roleManager))
            )
        );

        // Deploying an upgradeable proxy for CentralizedCustomERC20Gateway
        contracts.centralizedCustomErc20Gateway = Upgrades.deployTransparentProxy(
            "CentralizedCustomERC20Gateway.sol",
            initialOwner,
            abi.encodeCall(
                CentralizedCustomERC20Gateway.initialize,
                (address(0), address(0), contracts.roleManager, 0)
            )
        );

        // Deploying an upgradeable proxy for CentralizedETHGateway
        contracts.centralizedEthGateway = Upgrades.deployTransparentProxy(
            "CentralizedETHGateway.sol",
            initialOwner,
            abi.encodeCall(
                CentralizedETHGateway.initialize,
                (address(0), address(0), contracts.roleManager, 0)
            )
        );

        // Deploying an upgradeable proxy for CentralizedGatewayRouter
        contracts.centralizedGatewayRouter = Upgrades.deployTransparentProxy(
            "CentralizedGatewayRouter.sol",
            initialOwner,
            abi.encodeCall(
                CentralizedGatewayRouter.initialize,
                (address(0), address(0), contracts.roleManager)
            )
        );

        // Deploying an upgradeable proxy for CentralizedTwineMessenger
        contracts.centralizedTwineMessenger = Upgrades.deployTransparentProxy(
            "CentralizedTwineMessenger.sol",
            initialOwner,
            abi.encodeCall(
                CentralizedTwineMessenger.initialize,
                (
                    address(0),
                    contracts.roleManager
                )
            )
        );

        string memory twineObject = "centralized-contracts";
        vm.serializeAddress(
            twineObject,
            "CentralizedETHGateway",
            contracts.centralizedEthGateway
        );
        vm.serializeAddress(
            twineObject,
            "CentralizedRoleManager",
            contracts.roleManager
        );
        vm.serializeAddress(
            twineObject,
            "CentralizedGatewayRouter",
            contracts.centralizedGatewayRouter
        );
        vm.serializeAddress(
            twineObject,
            "CentralizedTwineMessenger",
            contracts.centralizedTwineMessenger
        );
        vm.serializeAddress(
            twineObject,
            "CentralizedCustomERC20Gateway",
            contracts.centralizedCustomErc20Gateway
        );
        vm.serializeAddress(twineObject, "CentralizedXERC20Gateway", address(0));
        vm.serializeAddress(twineObject, "FauxCoin", contracts.fauxCoin);

        string memory finalJson = vm.serializeAddress(
            twineObject,
            "EthSol",
            contracts.solToken
        );

        vm.writeJson(finalJson, exportPath);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Logging the address of the deployed proxies
        console.log("Deployed Contracts :");

        console.log("Centralized Eth Gatway :", contracts.centralizedEthGateway);
        console.log("Centralized Rolemanager :", contracts.roleManager);
        console.log("Centralized Gateway Router :", contracts.centralizedGatewayRouter);
        console.log("Centralized Twine Messenger :", contracts.centralizedTwineMessenger);
        console.log("Centralized Custom ERC20 Gateway:", contracts.centralizedCustomErc20Gateway);
    }
}
