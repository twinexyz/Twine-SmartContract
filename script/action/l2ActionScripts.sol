// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2XERC20Gateway} from "../../src/L2/gateways/L2XERC20Gateway.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {MockERC20} from "../../src/test/mocks/MockERC20.sol";

contract l2ActionScripts is Script {
    RoleManager roleManager;
    L2CustomERC20Gateway l2CustomERC20Gateway;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2XERC20Gateway l2XERC20Gateway;
    L2TwineMessenger l2TwineMessenger;
    MockERC20 l2Token;

    address l2CustomERC20GatewayAddress;
    address roleManagerAddress;
    address l2ETHGatewayAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address l1TwineMessengerAddress;
    address l2TwineMessengerAddress;
    address l2TokenAddress;
    address initialOwner;
    address consensusPrecompileAddress;
    address depositPrecompileAddress;
    address withdrawalPrecompileAddress;

    bytes32 constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");

    function setUp() public {
        l2CustomERC20GatewayAddress = 0x9eBb49B2004C753f6Fb8b3181C224a8972f70528;
        roleManagerAddress = 0xd829fcDDD9C9c7c50B7cB476596Ef0ff5889D543;
        l2ETHGatewayAddress = 0x7B31b399a224aD30D48838F55B41b6A6F1e033ED;
        l2GatewayRouterAddress = 0xe01c6c0E0997fa433357ec80BC21B1031CA7d4Cc;
        l2XERC20GatewayAddress = 0x1f5E9E9602bEb4D14c38952cB5504E4471E3328F;
        l2TwineMessengerAddress = 0xBAb8e13DeF75a95321E9f48d3ec57f2c0141A6c3;
        l2TokenAddress = 0x5DA6D90630A282169BCe92735cC1E4aAF14c9c64;
        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );
        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        consensusPrecompileAddress;

        //setup
        address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);
        tokens[0] = l2TokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        l2GatewayRouter.setERC20Gateway(tokens, gateways);
        l2GatewayRouter.setETHGateway(l2CustomERC20GatewayAddress);
        l2GatewayRouter.setDefaultERC20Gateway(l2ETHGatewayAddress);
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        l2CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2CustomERC20Gateway.setAddress(l1TwineMessengerAddress, l2GatewayRouterAddress,l2TwineMessengerAddress);
        l2XERC20Gateway.setAddress(l1TwineMessengerAddress, l2GatewayRouterAddress,l2TwineMessengerAddress);
        l2CustomERC20Gateway.setAddress(l1TwineMessengerAddress, l2GatewayRouterAddress,l2TwineMessengerAddress);
        l2ETHGateway.setAddress(l1TwineMessengerAddress, l2GatewayRouterAddress,l2TwineMessengerAddress);
        

        //mint Token and approve
        l2Token.approve(address(l2CustomERC20Gateway), 100000);
        l2Token.approve(address(l2GatewayRouter), 100000);
    }

    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        //withdraw of erc20
        l2GatewayRouter.withdrawERC20(address(l2Token), initialOwner, 10, 0);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
