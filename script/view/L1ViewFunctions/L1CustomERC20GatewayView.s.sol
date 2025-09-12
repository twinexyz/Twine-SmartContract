// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1CustomERC20Gateway} from "../../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract ViewRoleManagerAddress is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1CustomERC20Gateway"
        );
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log(
            "Role Manager Address :",
            l1CustomERC20Gateway.roleManager()
        );

        vm.stopBroadcast();
    }
}

contract ViewGatewayRouter is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1CustomERC20Gateway"
        );
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Gateway Router:", l1CustomERC20Gateway.gatewayRouter());

        vm.stopBroadcast();
    }
}

contract ViewTwineMessenger is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1CustomERC20Gateway"
        );
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Twine Messenger: ", l1CustomERC20Gateway.messenger());
        vm.stopBroadcast();
    }
}

contract ViewTokenMapping is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;
    address l1ERC20TokenAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1CustomERC20Gateway"
        );
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );

        l1ERC20TokenAddress = vm.envAddress("L1_TOKEN_ADDRESS");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log(
            "Token Mapping: \n",
            l1ERC20TokenAddress,
            "=>",
            l1CustomERC20Gateway.tokenMapping(l1ERC20TokenAddress)
        );
        vm.stopBroadcast();
    }
}

contract ViewChainId is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;

    
    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1CustomERC20Gateway"
        );
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Chain ID: ", l1CustomERC20Gateway.chainId());

        vm.stopBroadcast();
    }

}
