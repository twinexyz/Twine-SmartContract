// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L1CustomERC20Gateway} from "../../src/L1/gateways/L1CustomERC20Gateway.sol";
import {L1ETHGateway} from "../../src/L1/gateways/L1ETHGateway.sol";
import {L1GatewayRouter} from "../../src/L1/gateways/L1GatewayRouter.sol";
import {L1XERC20Gateway} from "../../src/L1/gateways/L1XERC20Gateway.sol";
import {L1MessageQueue} from "../../src/L1/rollup/L1MessageQueue.sol";
import {TwineChain} from "../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../src/L1/L1TwineMessenger.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {MockERC20} from "../../src/test/mocks/MockERC20.sol";

contract L1ActionScript is Script {
    MockERC20 token;
    TwineChain twineChain;
    RoleManager roleManager;
    L1ETHGateway l1ETHGateway;
    L1MessageQueue l1MessageQueue;
    L1GatewayRouter l1GatewayRouter;
    L1XERC20Gateway l1XERC20Gateway;
    L1TwineMessenger l1TwineMessenger;
    L1CustomERC20Gateway l1CustomERC20Gateway;

    address tokenAddress;
    address twineChainAddress;
    address roleManagerAddress;
    address l1ETHGatewayAddress;
    address l1MessageQueueAddress;
    address l1GatewayRouterAddress;
    address l1XERC20GatewayAddress;
    address l1TwineMessengerAddress;
    address l1CustomERC20GatewayAddress;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address Owner = vm.addr(deployerPrivateKey);

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.RoleManager"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ETHGateway"
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

        tokenAddress = 0x9323d71E54CFFE145Ae15Ad711a5aD52255A7866;

        twineChain = TwineChain(twineChainAddress);
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );
        roleManager = RoleManager(roleManager);
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1XERC20Gateway = L1XERC20Gateway(l1XERC20GatewayAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
        token = MockERC20(tokenAddress);
    }

    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        token.approve(l1CustomERC20GatewayAddress, 100000);
        token.approve(l1GatewayRouterAddress, 100000);

        l1GatewayRouter.depositERC20{value: 0}(
            tokenAddress,
            0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
            912,
            0
        );
        
        l1GatewayRouter.depositETH{value: 1 ether}(
            Owner,
            1000000000000000000,
            0
        );
        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}

