// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {L2ETHGateway} from "../../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../../src/L2/gateways/L2CustomERC20Gateway.sol";
import {L2TwineMessenger} from "../../../src/L2/L2TwineMessenger.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";

contract WithdrawETH is Script {
    L2ETHGateway l2ETHGateway;
    L2TwineMessenger l2TwineMessenger;
    address l2ETHGatewayAddress;
    address l2TwineMessengerAddress;

    address l2Token;
    string l1Token;
    string to;
    uint256 amount;
    uint256 chainId;
    uint256 gasLimit;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        l2ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".Twine.L2ETHGateway");
        l2TwineMessengerAddress = vm.parseJsonAddress(deployedJson, ".Twine.L2TwineMessenger");
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2TwineMessenger = L2TwineMessenger(l2TwineMessengerAddress);

        // read parameters dynamically
        l2Token = address(0);
        l1Token = vm.envString("L1_TOKEN");
        to = vm.envString("RECEIVER");
        amount = vm.envUint("AMOUNT");
        chainId = vm.envUint("CHAIN_ID");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        console.log("Messenger balance before deposit", address(l2TwineMessenger).balance);

        vm.startBroadcast(deployerPrivateKey);
        
        l2ETHGateway.withdrawETH{value: amount}(
            l2Token,
            l1Token,
            to, 
            amount, 
            chainId, 
            0
        );
        
        console.log("Messenger balance after deposit", address(l2TwineMessenger).balance);
        vm.stopBroadcast();
    }
}

contract WithdrawERC20 is Script {
    MockERC20 token;
    L2CustomERC20Gateway l2CustomERC20Gateway;

    address tokenAddress;
    address l2CustomERC20GatewayAddress;

    address _token;
    string to;
    uint256 amount;
    uint256 chainId;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(deployedJson, ".Twine.L2CustomERC20Gateway"); 
        tokenAddress = vm.parseJsonAddress(deployedJson, ".Twine.FauxCoin");

        l2CustomERC20Gateway = L2CustomERC20Gateway(l2CustomERC20GatewayAddress);
        token = MockERC20(tokenAddress);

        // Read parameters dynamically
        _token = vm.envAddress("TOKEN");
        to = vm.envString("RECEIVER");
        amount = vm.envUint("AMOUNT");
        chainId = vm.envUint("CHAIN_ID");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        token.mint(admin, 10 ether);
        token.approve(l2CustomERC20GatewayAddress, 5 ether);
        console.log("Balance of Admin before withdrawal: ", token.balanceOf(admin));
        
        l2CustomERC20Gateway.withdrawERC20(_token, to, amount, chainId, 0);

        console.log("Balance of Admin after withdrawal: ", token.balanceOf(admin));
        vm.stopBroadcast();
    }
}
contract GrantRole is Script {
    RoleManager roleManager;
    address roleManagerAddress;

    string role;
    address account;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        
        roleManagerAddress = vm.parseJsonAddress(deployedJson, ".Twine.L2RoleManager");
        roleManager = RoleManager(roleManagerAddress);

        // Read parameters dynamically
        role = vm.envString("ROLE");
        account = vm.envAddress("Account");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bytes32 encodedRole = keccak256(abi.encodePacked(role));
       
        vm.startBroadcast(deployerPrivateKey);

        roleManager.grantRole(encodedRole, account);
        roleManager.checkRole(encodedRole, account);

        vm.stopBroadcast();
    }
}

contract RevokeRole is Script {
    RoleManager roleManager;
    address roleManagerAddress;

    string role;
    address account;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        
        roleManagerAddress = vm.parseJsonAddress(deployedJson, ".Twine.L2RoleManager");
        roleManager = RoleManager(roleManagerAddress);

        // Read parameters dynamically
        role = vm.envString("ROLE");
        account = vm.envAddress("Account");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        bytes32 encodedRole = keccak256(abi.encodePacked(role));
       
        vm.startBroadcast(deployerPrivateKey);

        roleManager.revokeRole(encodedRole, account);
        
        vm.stopBroadcast();
    }
}
contract UpdateTokenMapping is Script {
    uint256 chainId;
    address l2ERC20TokenAddress;
    address l2CustomERC20GatewayAddress;
    string l1TokenAddress;
    L2CustomERC20Gateway l2CustomERC20Gateway;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );
        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2CustomERC20Gateway"
        );
        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );

        chainId = vm.envUint("CHAIN_ID");
        l2ERC20TokenAddress = vm.envAddress("L2_TOKEN_ADDRESS");
        l1TokenAddress = vm.envString("L1_TOKEN_ADDRESS");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        l2CustomERC20Gateway.updateTokenMapping(
            chainId,
            l2ERC20TokenAddress,
            l1TokenAddress
        );
        vm.stopBroadcast();
    }
}

