// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../src/test/mocks/MockERC20.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2XERC20Gateway} from "../../src/L2/gateways/L2XERC20Gateway.sol";
import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract L2ActionScript is Script {
    MockERC20 l2Erc20Token;
    RoleManager roleManager;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2XERC20Gateway l2XERC20Gateway;
    L2TwineMessenger l2TwineMessenger;
    L2CustomERC20Gateway l2CustomERC20Gateway;

    address roleManagerAddress;
    address l2ETHGatewayAddress;
    address l2ERC20TokenAddress;
    address l1ERC20TokenAddress;
    address l1EthGatewayAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address l1TwineMessengerAddress;
    address l2TwineMessengerAddress;
    address depositPrecompileAddress;
    address consensusPrecompileAddress;
    address withdrawalPrecompileAddress;
    address l2CustomERC20GatewayAddress;
    address l1CustomERC20GatewayAddress;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address Owner = vm.addr(deployerPrivateKey);

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );

        l1EthGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ETHGateway"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1CustomERC20Gateway"
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
        l2ERC20TokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2ERC20Token"
        );

        l1ERC20TokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ERC20Token"
        );

        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );

        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        l2XERC20Gateway = L2XERC20Gateway(l2XERC20GatewayAddress);
    }

    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();
        l2GatewayRouter.withdrawETH(Owner,1, 0, 0);
        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
