// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract UpgradeL2Contracts is Script {
    L2CustomERC20Gateway l2CustomERC20Gateway;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2TwineMessenger l2TwineMessenger;

    address l2CustomERC20GatewayAddress;
    address l2ETHGatewayAddress;
    address l2GatewayRouterAddress;
    address l2TwineMessengerAddress;

    address proxyEth;
    address proxyRouter;
    address proxyCustomERC20;
    address proxyTwineMessenger;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

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

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2TwineMessenger"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey); 

        L2GatewayRouter newL2GatewayRouter = new L2GatewayRouter();
        getProxyAdmin(l2GatewayRouterAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l2GatewayRouterAddress),
            address(newL2GatewayRouter),
            data
        );

        L2CustomERC20Gateway newL2CustomERC20Gateway = new L2CustomERC20Gateway();
        getProxyAdmin(l2CustomERC20GatewayAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l2CustomERC20GatewayAddress),
            address(newL2CustomERC20Gateway),
            data
        );

        L2TwineMessenger newL2TwineMessenger = new L2TwineMessenger();
        getProxyAdmin(l2TwineMessengerAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(l2TwineMessengerAddress),
            address(newL2TwineMessenger),
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