// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../src/test/mocks/MockERC20.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2XERC20Gateway} from "../../src/L2/gateways/L2XERC20Gateway.sol";
import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract l2SetupScripts is Script {
    MockERC20 l2Erc20Token;
    RoleManager roleManager;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2XERC20Gateway l2XERC20Gateway;
    L2TwineMessenger l2TwineMessenger;
    L2CustomERC20Gateway l2CustomERC20Gateway;

    address roleManagerAddress;
    address l2ETHGatewayAddress;
    address l2ERC20TokenAddress;
    address l1ERC20TokenAddress;
    address l1EthGatewayAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address l1TwineMessengerAddress;
    address l2TwineMessengerAddress;
    address depositPrecompileAddress;
    address consensusPrecompileAddress;
    address withdrawalPrecompileAddress;
    address l2CustomERC20GatewayAddress;
    address l1CustomERC20GatewayAddress;

    bytes32 constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address initialOwner = vm.addr(deployerPrivateKey);

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContractsAnvil.json"
        );

        l1EthGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ETHGateway"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1CustomERC20Gateway"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2CustomERC20Gateway"
        );
        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.RoleManager"
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

        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );

        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        l2XERC20Gateway = L2XERC20Gateway(l2XERC20GatewayAddress);
    }

    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);
        tokens[0] = l2ERC20TokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;

        roleManager.grantRole(CHAIN_ADMIN, initialOwner);

        l2GatewayRouter.setRoleManagerAddress(address(roleManager));
        l2GatewayRouter.setERC20Gateway(tokens, gateways);
        l2GatewayRouter.setETHGateway(l2CustomERC20GatewayAddress);
        l2GatewayRouter.setDefaultERC20Gateway(l2ETHGatewayAddress);

        l2CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2CustomERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2CustomERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);
        l2CustomERC20Gateway.updateTokenMapping(
            0,
            l2ERC20TokenAddress,
            l1ERC20TokenAddress
        );
        uint256[] memory chainId = new uint256[](1);
        address[] memory erc20CounterpartGateWay = new address[](1);
        chainId[0] = 0;
        erc20CounterpartGateWay[0] = l1CustomERC20GatewayAddress;
        l2CustomERC20Gateway.setCounterpartGateway(
            chainId,
            erc20CounterpartGateWay
        );

        l2XERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2XERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2XERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);

        l2ETHGateway.setRoleManagerAddress(roleManagerAddress);
        l2ETHGateway.setRouterAddress(l2GatewayRouterAddress);
        l2ETHGateway.setMessengerAddress(l2TwineMessengerAddress);
        uint256[] memory ethGatewaychainId = new uint256[](1);
        address[] memory ethCounterpartGateWay = new address[](1);
        ethGatewaychainId[0] = 0;
        ethCounterpartGateWay[0] = l1EthGatewayAddress;
        l2ETHGateway.setCounterpartGateway(
            ethGatewaychainId,
            ethCounterpartGateWay
        );

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
