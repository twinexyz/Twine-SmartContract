// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../src/test/mocks/MockERC20.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract L2SetupScript is Script {
    MockERC20 token;
    RoleManager roleManager;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2TwineMessenger l2TwineMessenger;
    L2CustomERC20Gateway l2CustomERC20Gateway;

    uint256 chainId;
    address tokenAddress;
    address roleManagerAddress;
    address l2ETHGatewayAddress;
    address l1ERC20TokenAddress;
    address l1ETHGatewayAddress;
    address l2ERC20TokenAddress;
    address l2MessageQueueAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address twineOperationsHandler;
    address l1TwineMessengerAddress;
    address l2TwineMessengerAddress;
    address bridgingPrecompileAddress;
    address consensusPrecompileAddress;
    address l1CustomERC20GatewayAddress;
    address l2CustomERC20GatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2RoleManager"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2CustomERC20Gateway"
        );

        l2ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2ETHGateway"
        );

        l2GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2GatewayRouter"
        );

        l2XERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2XERC20Gateway"
        );

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2TwineMessenger"
        );

        l2ERC20TokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2ERC20Token"
        );

        l1ERC20TokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ERC20Token"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ETHGateway"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1CustomERC20Gateway"
        );

        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1TwineMessenger"
        );

        chainId = 17000; //holesky chain Id

        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );

        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        l2TwineMessenger = L2TwineMessenger(l2TwineMessengerAddress);
        token = MockERC20(l2ERC20TokenAddress);
        bridgingPrecompileAddress = address(0x15);
        consensusPrecompileAddress = address(0x16);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);
        twineOperationsHandler = initialOwner;

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        //roleManager setup

        roleManager.grantRole(keccak256("CHAIN_ADMIN"), initialOwner);
        roleManager.checkRole(keccak256("CHAIN_ADMIN"), initialOwner);
        roleManager.grantRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            twineOperationsHandler
        );

        //L2ETHGateway setup
        l2ETHGateway.setRoleManagerAddress(roleManagerAddress);
        l2ETHGateway.setRouterAddress(l2GatewayRouterAddress);
        l2ETHGateway.setMessengerAddress(l2TwineMessengerAddress);
        uint256[] memory GatewaychainId = new uint256[](1);
        address[] memory l1Tokens = new address[](1);
        address[] memory CounterpartGateWay = new address[](1);
        GatewaychainId[0] = chainId;
        l1Tokens[0] = l1ERC20TokenAddress;
        CounterpartGateWay[0] = l1ETHGatewayAddress;
        l2ETHGateway.setCounterpartGateway(GatewaychainId,l1Tokens, CounterpartGateWay);

        //L2GatewayRouter Setup
        address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);
        tokens[0] = l2ERC20TokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        l2GatewayRouter.setRoleManagerAddress(address(roleManager));
        l2GatewayRouter.setERC20Gateway(tokens, gateways);
        l2GatewayRouter.setETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter.setDefaultERC20Gateway(l2CustomERC20GatewayAddress);

        //L2TwineMessenger
        l2TwineMessenger.setPrecompileAddress(consensusPrecompileAddress,bridgingPrecompileAddress);
        l2TwineMessenger.setRoleManager(roleManagerAddress);
        uint256[] memory chainIds = new uint256[](1);
        address[] memory counterpartMessenger = new address[](1);
        chainIds[0] = chainId;
        counterpartMessenger[0] = l1TwineMessengerAddress;
        l2TwineMessenger.setCounterpartMessenger(chainIds,counterpartMessenger);

        //L2CustomERC20Gateway
        l2CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2CustomERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2CustomERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);
        l2CustomERC20Gateway.updateTokenMapping(
            chainId,
            l2ERC20TokenAddress,
            l1ERC20TokenAddress
        );
        uint256[] memory chainIdset = new uint256[](1);
        address[] memory l1Token = new address[](1);
        address[] memory erc20CounterpartGateWay = new address[](1);

        chainIdset[0] = chainId;
        l1Token[0] = l1ERC20TokenAddress;
        erc20CounterpartGateWay[0] = l1CustomERC20GatewayAddress;
        l2CustomERC20Gateway.setCounterpartGateway(
            chainIdset,
            l1Token,
            erc20CounterpartGateWay
        );
         l2TwineMessenger.setCounterpartGateway(
            chainIdset,
            l1Token,
            erc20CounterpartGateWay
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
