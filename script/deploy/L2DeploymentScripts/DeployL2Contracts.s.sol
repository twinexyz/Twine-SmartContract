// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {L2OApp} from "../../../src/layerzero/L2Oapp.sol";
import {TwineDVN} from "../../../src/layerzero/TwineDVN.sol";
import {EndpointV2} from "../../../src/layerzero/EndpointV2.sol";
import {ReceiveUln302} from "../../../src/layerzero/ReceiveUln302.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {TwineStandardERC20} from "../../../src/libraries/token/TwineStandardERC20.sol";

import {L2MsgExecutor} from "../../../src/L2/L2MsgExecutor.sol";
import {L2TwineMessenger} from "../../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract DeployL2Contracts is Script {
    struct DeployedContracts {
        // Twine Contracts
        address roleManagerAddress;
        address L2GatewayRouterAddress;
        address L2CustomERC20GatewayAddress;
        address L2ETHGatewayAddress;
        address L2MessageExecutorAddress;
        address L2TwineMessengerAddress;
        // Tokens
        address solToken;
        address ethToken;
        address fauxCoin;
        // LayerZero Contracts
        address endpoint;
        address l2OApp;
        address dvn;
        address receiveLibrary;
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);
        string memory L1SetupJson = vm.readFile(
            "./script/utils/setupValues.json"
        );

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        DeployedContracts memory contracts;

        /****************************
         *  L2Contract Deployments  *
         ***************************/

        contracts.roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            initialOwner,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );

        // Deploying an upgradeable proxy for L2GatewayRouter
        contracts.L2GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L2GatewayRouter.sol",
            initialOwner,
            abi.encodeCall(
                L2GatewayRouter.initialize,
                (address(0), address(0), contracts.roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L2CustomERC20Gateway
        contracts.L2CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L2CustomERC20Gateway.sol",
            initialOwner,
            abi.encodeCall(
                L2CustomERC20Gateway.initialize,
                (
                    contracts.L2GatewayRouterAddress,
                    address(0),
                    contracts.roleManagerAddress
                )
            )
        );

        // Deploying an upgradeable proxy for L2ETHGateway
        contracts.L2ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L2ETHGateway.sol",
            initialOwner,
            abi.encodeCall(
                L2ETHGateway.initialize,
                (
                    contracts.L2GatewayRouterAddress,
                    address(0),
                    contracts.roleManagerAddress
                )
            )
        );

        contracts.L2MessageExecutorAddress = Upgrades.deployTransparentProxy(
            "L2MsgExecutor.sol",
            initialOwner,
            abi.encodeCall(
                L2MsgExecutor.initialize,
                (contracts.roleManagerAddress)
            )
        );

        // Deploying an upgradeable proxy for L2TwineMessenger
        contracts.L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            initialOwner,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (
                    0,
                    address(0),
                    contracts.roleManagerAddress,
                    contracts.L2MessageExecutorAddress
                )
            )
        );
        /***********************
         *  Token Deployments  *
         **********************/
        contracts.solToken = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            initialOwner,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("TwineSol", "TWS", 9, contracts.roleManagerAddress)
            )
        );
        contracts.ethToken = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            initialOwner,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("TwineEth", "TWE", 18, contracts.roleManagerAddress)
            )
        );
        contracts.fauxCoin = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            initialOwner,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("FauxCoin", "FAUX", 18, contracts.roleManagerAddress)
            )
        );

        /************************************
         *  LayerZero Contract Deployments  *
         ***********************************/
        uint32 twineEndpointId = uint32(vm.parseJsonUint(L1SetupJson, ".EndPointIdTwine"));


        contracts.endpoint = address(new EndpointV2(twineEndpointId, initialOwner));

        contracts.l2OApp = address(
            new L2OApp(
                contracts.endpoint,
                initialOwner,
                contracts.L2TwineMessengerAddress
            )
        );

        contracts.dvn = Upgrades.deployTransparentProxy(
            "TwineDVN.sol",
            initialOwner,
            abi.encodeCall(
                TwineDVN.initialize,
                (uint64(1), contracts.endpoint, contracts.roleManagerAddress, contracts.l2OApp)
            )
        );

        contracts.receiveLibrary = address(
            new ReceiveUln302(contracts.endpoint)
        );

        string memory twineObject = "TwineContracts";
        vm.serializeAddress(twineObject, "SolToken", contracts.solToken);
        vm.serializeAddress(twineObject, "ETHToken", contracts.ethToken);
        vm.serializeAddress(twineObject, "FauxCoin", contracts.fauxCoin);
        vm.serializeAddress(
            twineObject,
            "L2RoleManager",
            contracts.roleManagerAddress
        );
        vm.serializeAddress(
            twineObject,
            "L2ETHGateway",
            contracts.L2ETHGatewayAddress
        );
        vm.serializeAddress(
            twineObject,
            "L2GatewayRouter",
            contracts.L2GatewayRouterAddress
        );
        vm.serializeAddress(
            twineObject,
            "L2MsgExecutor",
            contracts.L2MessageExecutorAddress
        );
        vm.serializeAddress(twineObject, "L2XERC20Gateway", address(0));
        vm.serializeAddress(
            twineObject,
            "L2TwineMessenger",
            contracts.L2TwineMessengerAddress
        );
        vm.serializeAddress(twineObject, "L2OApp", contracts.l2OApp);
        vm.serializeAddress(twineObject, "L2DVN", contracts.dvn);
        vm.serializeAddress(
            twineObject,
            "L2ReceiveLib",
            contracts.receiveLibrary
        );
        vm.serializeAddress(twineObject, "L2Endpoint", contracts.endpoint);

        string memory finalJson = vm.serializeAddress(
            twineObject,
            "L2CustomERC20Gateway",
            contracts.L2CustomERC20GatewayAddress
        );

        vm.writeJson(finalJson, "./script/utils/twineAddresses.json");

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Logging the address of the deployed proxies
        console.log("Deployed Contracts :");
        console.log("L2 SolToken:", contracts.solToken);
        console.log("L2 EthToken:", contracts.ethToken);
        console.log("L2 RandomToken", contracts.fauxCoin);
        console.log("L2 Rolemanager :", contracts.roleManagerAddress);
        console.log("L2 Eth Gateway :", contracts.L2ETHGatewayAddress);
        console.log("L2 Gateway Router :", contracts.L2GatewayRouterAddress);
        console.log("L2 Twine Messenger :", contracts.L2TwineMessengerAddress);
        console.log("L2 Message Executor  :", contracts.L2MessageExecutorAddress);
        console.log("L2 Custom ERC20 Gateway :", contracts.L2CustomERC20GatewayAddress);
    }
}
