// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";

contract SetRoleManager is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1ETHGateway.setRoleManagerAddress(roleManagerAddress);
        vm.stopBroadcast();
    }
}

contract setGatewayRouter is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address l1GatewayRouterAddress;
    
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        l1GatewayRouterAddress = vm.envAddress("GATEWAY_ROUTER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1ETHGateway.setGatewayRouter(l1GatewayRouterAddress);
        vm.stopBroadcast();
    }
}

contract setTwineMessenger is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address l1TwineMessengerAddress;
    
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        l1TwineMessengerAddress = vm.envAddress("TWINE_MESSENGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1ETHGateway.setTwineMessenger(l1TwineMessengerAddress);
        vm.stopBroadcast();
    }
}

contract setL2TokenAddress is Script {
    L1ETHGateway l1ETHGateway;
    address l1ETHGatewayAddress;
    address l2ETHTokenAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1ETHGateway");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);

        l2ETHTokenAddress = vm.envAddress("L2_ETH_TOKEN_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l1ETHGateway.setL2TokenAddress(l2ETHTokenAddress);
        vm.stopBroadcast();
    }
}

contract SetChainId is Script {
    L1ETHGateway l1EthGateway;
    address l1EthGatewayAddress;

    uint256 chainId;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        
        l1EthGatewayAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1ETHGateway");
        l1EthGateway = L1ETHGateway(l1EthGatewayAddress);

        // Read parameters dynamically
        chainId = vm.envUint("CHAIN_ID");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
       
        vm.startBroadcast(deployerPrivateKey);

        l1EthGateway.setChainId(uint64(chainId));
        
        vm.stopBroadcast();
    }
}