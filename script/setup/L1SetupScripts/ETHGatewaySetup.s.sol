// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";

contract SetRoleManager is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Role Manager Address", l1ETHGateway.roleManager());

        l1ETHGateway.setRoleManagerAddress(roleManagerAddress);

        console.log("New Role Manager Address", l1ETHGateway.roleManager());
        vm.stopBroadcast();
    }
}

contract setGatewayRouter is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address l1GatewayRouterAddress;
    
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        l1GatewayRouterAddress = vm.envAddress("GATEWAY_ROUTER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Gateway Router: ", l1ETHGateway.gatewayRouter());

        l1ETHGateway.setGatewayRouter(l1GatewayRouterAddress);

        console.log("New Gateway Router: ", l1ETHGateway.gatewayRouter());
        vm.stopBroadcast();
    }
}

contract setTwineMessenger is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address l1TwineMessengerAddress;
    
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        l1TwineMessengerAddress = vm.envAddress("TWINE_MESSENGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Twine Messenger: ", l1ETHGateway.messenger());

        l1ETHGateway.setTwineMessenger(l1TwineMessengerAddress);

        console.log("New Twine Messenger: ", l1ETHGateway.messenger());
        vm.stopBroadcast();
    }
}

contract setL2TokenAddress is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address l2ETHTokenAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        l2ETHTokenAddress = vm.envAddress("L2_ETH_TOKEN_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous L2 Token Address", l1ETHGateway.l2TokenAddress());

        l1ETHGateway.setL2TokenAddress(l2ETHTokenAddress);

        console.log("New L2 Token Address", l1ETHGateway.l2TokenAddress());
        vm.stopBroadcast();
    }
}

contract SetChainId is Script {
    L1ETHGateway l1EthGateway;
    address l1EthGatewayAddress;

    uint256 chainId;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        
        l1EthGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1EthGateway = L1ETHGateway(l1EthGatewayAddress);

        chainId = vm.envUint("CHAIN_ID");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
       
        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Chain ID", l1EthGateway.chainId());

        l1EthGateway.setChainId(uint64(chainId));
        
        console.log("New Chain ID", l1EthGateway.chainId());
        vm.stopBroadcast();
    }
}