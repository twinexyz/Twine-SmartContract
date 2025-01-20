// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";
import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";

contract DepositETH is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;

    uint256 depositAmount;
    address receiver;

    function setUp() public {
        string memory deployedJson = vm.readFile("./scripts/utils/deployedContracts.json");

        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1GatewayRouter");
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);

        // Read parameters dynamically or use defaults
        depositAmount = vm.envUint("DEPOSIT_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        l1GatewayRouter.depositETH{value: depositAmount}(
            receiver,
            depositAmount,
            0
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}