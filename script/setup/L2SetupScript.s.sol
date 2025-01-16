// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../src/test/mocks/MockERC20.sol";
import {MockERC20_9Decimals} from "../../src/test/mocks/MockERC20_9Decimals.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract L2SetupScript is Script {
    RoleManager roleManager;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2TwineMessenger l2TwineMessenger;
    L2CustomERC20Gateway l2CustomERC20Gateway;
    MockERC20_9Decimals solToken;
    MockERC20 ethToken ;
    MockERC20 jgToken ;

    uint256 chainIdEth;
    uint256 chainIdSolana;
    address solTokenAddress;
    address ethTokenAddress;
    address jgTokenAddress;
    address roleManagerAddress;
    address l2ETHGatewayAddress;
    address l1JgTokenAddress;
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

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.L2TwineMessenger"
        );

        solTokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.SolToken" 
        );

        ethTokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.ETHToken" 
        );

        jgTokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Twine.JGToken" 
        );

        l1JgTokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.JGToken"
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

        chainIdEth = 17000; //holesky chain Id
        chainIdSolana = 900;

        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );

        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        l2TwineMessenger = L2TwineMessenger(l2TwineMessengerAddress);
        solToken = MockERC20_9Decimals(solTokenAddress);
        ethToken = MockERC20(ethTokenAddress);
        jgToken = MockERC20(jgTokenAddress);
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
        string[] memory l1Tokens = new string[](1);
        string[] memory CounterpartGateWay = new string[](1);
        GatewaychainId[0] = chainIdEth;
        l1Tokens[0] =  addressToString(l1JgTokenAddress);
        CounterpartGateWay[0] = addressToString(l1ETHGatewayAddress);

        //L2GatewayRouter Setup
        address[] memory tokens = new address[](3);
        address[] memory gateways = new address[](3);
        tokens[0] = solTokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        tokens[0] = ethTokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        tokens[0] = jgTokenAddress;
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
        chainIds[0] = chainIdEth;
        counterpartMessenger[0] = l1TwineMessengerAddress;
        l2TwineMessenger.setCounterpartMessenger(chainIds,counterpartMessenger);

        //L2CustomERC20Gateway
        l2CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2CustomERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2CustomERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);

        l2CustomERC20Gateway.updateTokenMapping(
            chainIdEth,
            jgTokenAddress,
            addressToString(l1JgTokenAddress)
        );

        l2CustomERC20Gateway.updateTokenMapping(
            chainIdEth,
            address(ethToken),
            "0x0000000000000000000000000000000000000000"
        );

        l2CustomERC20Gateway.updateTokenMapping(
            chainIdSolana,
            solTokenAddress,
            "11111111111111111111111111111111"
        );

        // TODO: Map JG Token on Twine to JG Token on solana


        uint256[] memory chainIdset = new uint256[](1);
        string[] memory l1Token = new string[](1);
        string[] memory erc20CounterpartGateWay = new string[](1);

        chainIdset[0] = chainIdEth;
        l1Token[0] = addressToString(l1JgTokenAddress);
        erc20CounterpartGateWay[0] = addressToString(l1CustomERC20GatewayAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }

    function addressToString(
        address _address
    ) public pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}
