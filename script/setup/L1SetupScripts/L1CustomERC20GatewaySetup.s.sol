// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1CustomERC20Gateway} from "../../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract SetRoleManagerAddress is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;
    address roleManagerAddress;

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

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Previous Role Manager Address",
            l1CustomERC20Gateway.roleManager()
        );

        l1CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);

        console.log(
            "New Role Manager Address",
            l1CustomERC20Gateway.roleManager()
        );
        vm.stopBroadcast();
    }
}

contract SetGatewayRouter is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;
    address l1GatewayRouterAddress;

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

        l1GatewayRouterAddress = vm.envAddress("GATEWAY_ROUTER_ADDRESS");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Previous Gateway Router: ",
            l1CustomERC20Gateway.gatewayRouter()
        );

        l1CustomERC20Gateway.setGatewayRouter(l1GatewayRouterAddress);

        console.log(
            "New Gateway Router: ",
            l1CustomERC20Gateway.gatewayRouter()
        );
        vm.stopBroadcast();
    }
}

contract SetTwineMessenger is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;
    address l1TwineMessengerAddress;

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

        l1TwineMessengerAddress = vm.envAddress("TWINE_MESSENGER_ADDRESS");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Previous Twine Messenger: ",
            l1CustomERC20Gateway.messenger()
        );

        l1CustomERC20Gateway.setTwineMessenger(l1TwineMessengerAddress);

        console.log("New Twine Messenger: ", l1CustomERC20Gateway.messenger());
        vm.stopBroadcast();
    }
}

contract UpdateTokenMapping is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;
    address l1ERC20TokenAddress;
    address l2ERC20TokenAddress;

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
        l2ERC20TokenAddress = vm.envAddress("L2_TOKEN_ADDRESS");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1CustomERC20Gateway.updateTokenMapping(
            l1ERC20TokenAddress,
            l2ERC20TokenAddress
        );

        console.log(
            "New Token Mapping: ",
            l1CustomERC20Gateway.tokenMapping(l1ERC20TokenAddress)
        );
        vm.stopBroadcast();
    }
}

contract RemoveTokenMapping is Script {
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
        l1CustomERC20Gateway.removeTokenMapping(
            l1ERC20TokenAddress
        );
        vm.stopBroadcast();
    }
}

contract SetChainId is Script {
    L1CustomERC20Gateway l1CustomERC20Gateway;
    address l1CustomERC20GatewayAddress;

    uint256 chainId;

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

        // Read parameters dynamically
        chainId = vm.envUint("CHAIN_ID");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Chain ID", l1CustomERC20Gateway.chainId());

        l1CustomERC20Gateway.setChainId(uint64(chainId));

        console.log("New Chain ID", l1CustomERC20Gateway.chainId());
        vm.stopBroadcast();
    }
}
