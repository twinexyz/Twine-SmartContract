// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";

contract ViewRoleManagerAddress is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1GatewayRouter"
        );
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Role Manager Address: ", l1GatewayRouter.roleManager());
        vm.stopBroadcast();
    }
}

contract ViewETHGateway is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1GatewayRouter"
        );
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("ETH Gateway Address: ", l1GatewayRouter.ethGateway());
        vm.stopBroadcast();
    }
}

contract ViewDefaultERC20Gateway is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1GatewayRouter"
        );
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log(
            "Default ERC20 Gateway: ",
            l1GatewayRouter.defaultERC20Gateway()
        );
        vm.stopBroadcast();
    }
}

contract ViewERC20Gateway is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;
    address token;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1GatewayRouter"
        );
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);

        token = vm.envAddress("TOKEN");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "ERC20 Gateway: \n",
            token,
            "=>",
            l1GatewayRouter.ERC20Gateway(token)
        );

        vm.stopBroadcast();
    }
}

