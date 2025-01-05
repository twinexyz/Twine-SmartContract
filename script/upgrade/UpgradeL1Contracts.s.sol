// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {MockERC20} from "../../src/test/mocks/MockERC20.sol";
import {TwineChain} from "../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../src/L1/L1TwineMessenger.sol";
import {L1ETHGateway} from "../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageQueue} from "../../src/L1/rollup/L1MessageQueue.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {L1GatewayRouter} from "../../src/L1/gateways/L1GatewayRouter.sol";
import {L1CustomERC20Gateway} from "../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract UpgradeL1Contracts is Script {
    MockERC20 token;
    TwineChain twineChain;
    RoleManager roleManager;
    L1ETHGateway l1ETHGateway;
    L1MessageQueue l1MessageQueue;
    L1GatewayRouter l1GatewayRouter;
    L1TwineMessenger l1TwineMessenger;
    L1CustomERC20Gateway l1CustomERC20Gateway;

    uint256 chainId;
    bytes32 programVkey;
    address tokenAddress;
    address verifierAddress;
    address twineChainAddress;
    address roleManagerAddress;
    address l1ETHGatewayAddress;
    address l1ERC20TokenAddress;
    address l1MessageQueueAddress;
    address l1GatewayRouterAddress;
    address l1XERC20GatewayAddress;
    address twineOperationsHandler;
    address l1TwineMessengerAddress;
    address l1CustomERC20GatewayAddress;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1RoleManager"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ETHGateway"
        );

        l1ERC20TokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ERC20Token"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1CustomERC20Gateway"
        );

        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );

        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1GatewayRouter"
        );

        l1XERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1XERC20Gateway"
        );

        l1MessageQueueAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1MessageQueue"
        );

        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1TwineMessenger"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        TwineChain newTwineChain = new TwineChain();
        getProxyAdmin(twineChainAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(twineChainAddress),
            address(newTwineChain),
            data
        );

        L1ETHGateway newL2ETHGateway = new L1ETHGateway();
        getProxyAdmin(l1ETHGatewayAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l1ETHGatewayAddress),
            address(newL2ETHGateway),
            data
        );

        L1MessageQueue newMessageQueue = new L1MessageQueue();
        getProxyAdmin(l1MessageQueueAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l1MessageQueueAddress),
            address(newMessageQueue),
            data
        );

        L1GatewayRouter newL1GatewayRouter = new L1GatewayRouter();
        getProxyAdmin(l1GatewayRouterAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l1GatewayRouterAddress),
            address(newL1GatewayRouter),
            data
        );

        L1TwineMessenger newL1TwineMessenger = new L1TwineMessenger();
        getProxyAdmin(l1TwineMessengerAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l1TwineMessengerAddress),
            address(newL1TwineMessenger),
            data
        );

        L1CustomERC20Gateway newL1CustomERC20Gateway = new L1CustomERC20Gateway();
        getProxyAdmin(l1CustomERC20GatewayAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l1CustomERC20GatewayAddress),
            address(newL1CustomERC20Gateway),
            data
        );
        vm.stopBroadcast();
    }

    function getProxyAdmin(
        address proxyAddress
    ) internal view returns (ProxyAdmin contractAdmin) {
        address proxyAdminContractAddress = Upgrades.getAdminAddress(
            address(proxyAddress)
        );
        contractAdmin = ProxyAdmin(proxyAdminContractAddress);
    }
   
}
