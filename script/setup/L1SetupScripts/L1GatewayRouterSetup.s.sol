// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";

contract SetRoleManagerAddress is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".L1GatewayRouter");
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Role Manager Address", l1GatewayRouter.roleManager());

        l1GatewayRouter.setRoleManagerAddress(roleManagerAddress);

        console.log("New Role Manager Address", l1GatewayRouter.roleManager());
        vm.stopBroadcast();
    }
}

contract SetETHGateway is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;
    address l1ETHGatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".L1GatewayRouter");
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);

        l1ETHGatewayAddress = vm.envAddress("ETH_GATEWAY_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous ETH Gateway Address: ", l1GatewayRouter.ethGateway());

        l1GatewayRouter.setETHGateway(l1ETHGatewayAddress);
        
        console.log("New ETH Gateway Address: ", l1GatewayRouter.ethGateway());
        vm.stopBroadcast();
    }
}

contract SetDefaultERC20Gateway is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;
    address l1CustomERC20GatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".L1GatewayRouter");
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);

        l1CustomERC20GatewayAddress = vm.envAddress("CUSTOM_ERC20_GATEWAY_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Default ERC20 Gateway: ", l1GatewayRouter.defaultERC20Gateway());

        l1GatewayRouter.setDefaultERC20Gateway(l1CustomERC20GatewayAddress);

        console.log("New Default ERC20 Gateway: ", l1GatewayRouter.defaultERC20Gateway());
        vm.stopBroadcast();
    }
}

contract SetERC20Gateway is Script {
    L1GatewayRouter l1GatewayRouter;
    address l1GatewayRouterAddress;

    address[] tokens;
    address[] gateways;
    uint64 tokenCount;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".L1GatewayRouter");
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);

        string memory tokenStr = vm.envString("TOKENS");
        tokens = _parseAddressArray(tokenStr);

        string memory gatewayStr = vm.envString("GATEWAYS");
        gateways = _parseAddressArray(gatewayStr);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        l1GatewayRouter.setERC20Gateway(tokens, gateways);
        console.log("New ERC20 Gateway set: ", l1GatewayRouter.ERC20Gateway(tokens[0]));

        vm.stopBroadcast();
    }

    function _parseAddressArray(string memory str) internal pure returns (address[] memory) {
        string[] memory parts = vm.split(str, ",");
        address[] memory result = new address[](parts.length);
        for(uint64 i = 0; i < parts.length; i++) {
            result[i] = vm.parseAddress(parts[i]);
        }
        return result;
    }
}