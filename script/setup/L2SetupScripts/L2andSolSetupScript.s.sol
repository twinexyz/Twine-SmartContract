// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {MockERC20_9Decimals} from "../../../src/test/mocks/MockERC20_9Decimals.sol";
import {L2TwineMessenger} from "../../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../../src/L2/gateways/L2ETHGateway.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {L2GatewayRouter} from "../../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../../src/L2/gateways/L2CustomERC20Gateway.sol";
import {TwineSystemStorage} from "../../../src/L2/TwineSystemStorage.sol";

contract L2andSolSetupScript is Script {
    RoleManager roleManager;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2TwineMessenger l2TwineMessenger;
    L2CustomERC20Gateway l2CustomERC20Gateway;
    TwineSystemStorage twineSystemStorage;
    MockERC20_9Decimals solToken;
    MockERC20 ethToken ;
    MockERC20 fauxCoin;

    uint256 chainIdEth;
    uint256 chainIdSolana;
    address solTokenAddress;
    address ethTokenAddress;
    address fauxCoinAddress;    
    address roleManagerAddress;
    address l2MessageExecutorAddress;
    address l2ETHGatewayAddress;
    address l2ERC20TokenAddress;
    address l2MessageHandlerAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address twineOperationsHandler;
    address l2TwineMessengerAddress;
    address bridgingPrecompileAddress;
    address consensusPrecompileAddress;
    address twineSystemStorageAddress;
    address l2CustomERC20GatewayAddress;


    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2RoleManager"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2CustomERC20Gateway"
        );

        l2ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2ETHGateway"
        );

        l2GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2GatewayRouter"
        );

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2TwineMessenger"
        );

        l2MessageExecutorAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2MsgExecutor"
        );

        solTokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".SolToken" 
        );

        ethTokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".ETHToken" 
        );

        fauxCoinAddress  = vm.parseJsonAddress(
            deployedJson,
            ".FauxCoin" 
        );


        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );

        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        l2TwineMessenger = L2TwineMessenger(l2TwineMessengerAddress);
        solToken = MockERC20_9Decimals(solTokenAddress);
        ethToken = MockERC20(ethTokenAddress);
        fauxCoin  = MockERC20(fauxCoinAddress);
        consensusPrecompileAddress = address(0x15);
        bridgingPrecompileAddress = address(0x16);
        twineSystemStorageAddress = address(0x17);
        twineSystemStorage = TwineSystemStorage(twineSystemStorageAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);
        twineOperationsHandler = initialOwner;

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // setup twine messenger address
        twineSystemStorage.setTwineMessenger(l2TwineMessengerAddress);

        //roleManager setup
        roleManager.grantRole(keccak256("CHAIN_ADMIN"), initialOwner);
        roleManager.checkRole(keccak256("CHAIN_ADMIN"), initialOwner);
        roleManager.grantRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            twineOperationsHandler
        );
        roleManager.grantRole(keccak256("TWINE_GATEWAYS"), l2CustomERC20GatewayAddress);
        roleManager.checkRole(keccak256("TWINE_GATEWAYS"), l2CustomERC20GatewayAddress);
        roleManager.grantRole(keccak256("TWINE_MESSENGER"), l2TwineMessengerAddress);
        roleManager.checkRole(keccak256("TWINE_MESSENGER"), l2TwineMessengerAddress);

        //L2ETHGateway setup
        l2ETHGateway.setRoleManagerAddress(roleManagerAddress);
        l2ETHGateway.setRouterAddress(l2GatewayRouterAddress);
        l2ETHGateway.setMessengerAddress(l2TwineMessengerAddress);

        //L2GatewayRouter Setup
        address[] memory tokens = new address[](3);
        address[] memory gateways = new address[](3);
        tokens[0] = solTokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        tokens[1] = ethTokenAddress;
        gateways[1] = l2CustomERC20GatewayAddress;
        tokens[2] = fauxCoinAddress;
        gateways[2] = l2CustomERC20GatewayAddress;
        l2GatewayRouter.setRoleManagerAddress(address(roleManager));
        l2GatewayRouter.setERC20Gateway(tokens, gateways);
        l2GatewayRouter.setETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter.setDefaultERC20Gateway(l2CustomERC20GatewayAddress);

        //L2TwineMessenger
        l2TwineMessenger.setPrecompileAddress(consensusPrecompileAddress,bridgingPrecompileAddress);
        l2TwineMessenger.setRoleManager(roleManagerAddress);
        l2TwineMessenger.setSystemStorageContract(twineSystemStorageAddress);
        l2TwineMessenger.setMsgExecutorAddress(l2MessageExecutorAddress);

        //L2CustomERC20Gateway
        l2CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2CustomERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2CustomERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);

        // Update token mapping
        // l2CustomERC20Gateway.updateTokenMapping(
        //     chainIdSolana,
        //     solTokenAddress,
        //     "11111111111111111111111111111111"
        // );

        // l2CustomERC20Gateway.updateTokenMapping(
        //     chainIdSolana,
        //     fauxCoinAddress,
        //     solanaFauxCoinAddress
        // );

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
