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
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2CustomERC20Gateway"
        );
        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.RoleManager"
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
        console.log("Messenger Address", l2TwineMessengerAddress);
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
        l2CustomERC20Gateway.setAddress(
            l1TwineMessengerAddress,
            l2GatewayRouterAddress,
            l2TwineMessengerAddress
        );
        l2XERC20Gateway.setAddress(
            l1TwineMessengerAddress,
            l2GatewayRouterAddress,
            l2TwineMessengerAddress
        );
        l2CustomERC20Gateway.setAddress(
            l1TwineMessengerAddress,
            l2GatewayRouterAddress,
            l2TwineMessengerAddress
        );
        l2ETHGateway.setAddress(
            l1TwineMessengerAddress,
            l2GatewayRouterAddress,
            l2TwineMessengerAddress
        );
        //mint Token and approve
        l2Token.approve(address(l2CustomERC20Gateway), 100000);
        l2Token.approve(address(l2GatewayRouter), 100000);
    }

    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        //withdraw of erc20
        l2GatewayRouter.withdrawERC20(address(l2Token), initialOwner, 10,1, 0);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
