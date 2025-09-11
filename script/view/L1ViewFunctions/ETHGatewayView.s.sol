// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";

contract ViewRoleManager is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Role Manager Address", l1ETHGateway.roleManager());
        vm.stopBroadcast();
    }
}

contract ViewGatewayRouter is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Gateway Router: ", l1ETHGateway.gatewayRouter());
        vm.stopBroadcast();
    }
}


contract ViewTwineMessenger is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Twine Messenger: ", l1ETHGateway.messenger());
        vm.stopBroadcast();
    }
}

contract ViewL2TokenAddress is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("L2 Token Address", l1ETHGateway.l2TokenAddress());
        vm.stopBroadcast();
    }
}

contract ViewChainId is Script {
    L1ETHGateway l1EthGateway;
    address l1EthGatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        
        l1EthGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1EthGateway = L1ETHGateway(l1EthGatewayAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
       
        vm.startBroadcast(deployerPrivateKey);
        console.log("Chain ID: ", l1EthGateway.chainId());
        vm.stopBroadcast();
    }
}