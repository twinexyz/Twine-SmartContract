// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2XERC20Gateway} from "../../src/L2/gateways/L2XERC20Gateway.sol";
import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";


contract UpgradeL2Contracts is Script {
    L2CustomERC20Gateway l2CustomERC20Gateway;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2XERC20Gateway l2XERC20Gateway;
    L2TwineMessenger l2TwineMessenger;

    address l2CustomERC20GatewayAddress;
    address l2ETHGatewayAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address l2TwineMessengerAddress;

    address proxyEth;
    address proxyRouter;
    address proxyCustomERC20;
    address proxyXERC20;
    address proxyTwineMessenger;

    bytes32 constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2CustomERC20Gateway"
        );

        l2ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2ETHGateway"
        );
        l2GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2GatewayRouter"
        );
        l2XERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2XERC20Gateway"
        );
        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2TwineMessenger"
        );

        proxyEth = vm.parseJsonAddress(
            deployedJson,
            ".ProxyAdminTwine.proxyEth"
        );
        proxyRouter = vm.parseJsonAddress(
            deployedJson,
            ".ProxyAdminTwine.proxyRouter"
        );
        proxyCustomERC20 = vm.parseJsonAddress(
            deployedJson,
            ".ProxyAdminTwine.proxyCustomERC20"
        );
        proxyXERC20 = vm.parseJsonAddress(
            deployedJson,
            ".ProxyAdminTwine.proxyXERC20"
        );

        proxyTwineMessenger = vm.parseJsonAddress(
            deployedJson,
            ".ProxyAdminTwine.proxyTwineMessenger"
        );

    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Read private key from environment variable

        vm.startBroadcast(deployerPrivateKey);
        // Create an instance of ProxyAdmin
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyEth);
        bytes memory data = "";

        L2ETHGateway newL2ETHGateway = new L2ETHGateway();

        // Upgrade the proxy to the new implementation and call initialize

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2ETHGatewayAddress),
            address(newL2ETHGateway),
            data
        );

        proxyAdmin = ProxyAdmin(proxyRouter);
        L2GatewayRouter newL2GatewayRouter = new L2GatewayRouter();

        // Upgrade the proxy to the new implementation and call initialize

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2GatewayRouterAddress),
            address(newL2GatewayRouter),
            data
        );

        // Upgrade the proxy to the new implementation and call initialize

        proxyAdmin = ProxyAdmin(proxyCustomERC20);
        L2CustomERC20Gateway newL2CustomERC20Gateway = new L2CustomERC20Gateway();
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2CustomERC20GatewayAddress),
            address(newL2CustomERC20Gateway),
            data
        );

        proxyAdmin = ProxyAdmin(proxyXERC20);
        L2XERC20Gateway newL2XERC20Gateway = new L2XERC20Gateway();

        // Upgrade the proxy to the new implementation and call initialize

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2XERC20GatewayAddress),
            address(newL2XERC20Gateway),
            data
        );

        proxyAdmin = ProxyAdmin(proxyTwineMessenger);
        L2TwineMessenger newL2TwineMessenger = new L2TwineMessenger();

        // Upgrade the proxy to the new implementation and call initialize

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2TwineMessengerAddress),
            address(newL2TwineMessenger),
            data
        );
    }
}