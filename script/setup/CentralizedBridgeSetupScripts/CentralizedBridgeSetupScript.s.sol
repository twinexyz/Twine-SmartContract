// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {CentralizedTwineMessenger} from "../../../src/centralizedBridge/CentralizedTwineMessenger.sol";
import {CentralizedETHGateway} from "../../../src/centralizedBridge/centralizedGateways/CentralizedETHGateway.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {CentralizedGatewayRouter} from "../../../src/centralizedBridge/centralizedGateways/CentralizedGatewayRouter.sol";
import {CentralizedCustomERC20Gateway} from "../../../src/centralizedBridge/centralizedGateways/CentralizedCustomERC20Gateway.sol";

contract CentralizedBridgeSetupScript is Script {
    // Contracts
    RoleManager roleManager;
    CentralizedETHGateway centralizedETHGateway;
    CentralizedGatewayRouter centralizedGatewayRouter;
    CentralizedTwineMessenger centralizedTwineMessenger;
    CentralizedCustomERC20Gateway centralizedCustomERC20Gateway;

    // Setup Values
    uint64 chainId;
    address chainAdmin;
    address twineOperationsHandler;

    // Twine Contract Addresses
    address twineFauxCoinAddress;
    address twineSolTokenAddress;
    address twineEthTokenAddress;
    address twineETHGatewayAddress;
    address twineTwineMessengerAddress;
    address twineCustomERC20GatewayAddress;

    // Bridge Contract Addresses
    address roleManagerAddress;
    address centralizedFauxCoinAddress;
    address centralizedETHGatewayAddress;
    address centralizedEthSolTokenAddress;
    address centralizedGatewayRouterAddress;
    address centralizedXERC20GatewayAddress;
    address centralizedTwineMessengerAddress;
    address centralizedCustomERC20GatewayAddress;

    function setUp() public {
        // <--------------------------- Read Json Files ---------------------------->
        string memory deployedBridgeJson = vm.readFile(
            "./script/utils/CentralizeBridgeAddresses.json"
        );

        string memory deployedTwineJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        string memory L1SetupJson = vm.readFile("./script/utils/setupValues.json");

        // <-------------------- Deployed L1 Contract Addresses -------------------->
        roleManagerAddress = vm.parseJsonAddress(
            deployedBridgeJson,
            ".CentralizedRoleManager"
        );

        centralizedETHGatewayAddress = vm.parseJsonAddress(
            deployedBridgeJson,
            ".CentralizedETHGateway"
        );

        centralizedCustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedBridgeJson,
            ".CentralizedCustomERC20Gateway"
        );

        centralizedGatewayRouterAddress = vm.parseJsonAddress(
            deployedBridgeJson,
            ".CentralizedGatewayRouter"
        );

        centralizedXERC20GatewayAddress = vm.parseJsonAddress(
            deployedBridgeJson,
            ".CentralizedXERC20Gateway"
        );

        centralizedTwineMessengerAddress = vm.parseJsonAddress(
            deployedBridgeJson,
            ".CentralizedTwineMessenger"
        );

        centralizedFauxCoinAddress = vm.parseJsonAddress(deployedBridgeJson, ".FauxCoin");

        centralizedEthSolTokenAddress = vm.parseJsonAddress(deployedBridgeJson, ".EthSol");

        // <-------------------- Deployed L2 Contract Addresses -------------------->

        twineTwineMessengerAddress = vm.parseJsonAddress(
            deployedTwineJson,
            ".L2TwineMessenger"
        );

        twineFauxCoinAddress = vm.parseJsonAddress(deployedTwineJson, ".FauxCoin");
        twineSolTokenAddress = vm.parseJsonAddress(deployedTwineJson, ".SolToken");
        twineEthTokenAddress = vm.parseJsonAddress(deployedTwineJson, ".ETHToken");
        
        twineCustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedTwineJson,
            ".L2CustomERC20Gateway"
        );

        twineETHGatewayAddress = vm.parseJsonAddress(
            deployedTwineJson,
            ".L2ETHGateway"
        );

        // <-------------------- L1 Contracts -------------------->

        centralizedCustomERC20Gateway = CentralizedCustomERC20Gateway(
            centralizedCustomERC20GatewayAddress
        );
        roleManager = RoleManager(roleManagerAddress);
        centralizedETHGateway = CentralizedETHGateway(centralizedETHGatewayAddress);
        centralizedGatewayRouter = CentralizedGatewayRouter(centralizedGatewayRouterAddress);
        centralizedTwineMessenger = CentralizedTwineMessenger(centralizedTwineMessengerAddress);

        // <--------------- Setup Values --------------->

        chainId = uint64(vm.parseJsonUint(L1SetupJson, ".ChainIdEth"));
        chainAdmin = vm.parseJsonAddress(L1SetupJson, ".L1ChainAdmin");
        twineOperationsHandler = vm.parseJsonAddress(
            L1SetupJson,
            ".L1TwineOperationHandler"
        );
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        //roleManager setup
        roleManager.grantRole(keccak256("CHAIN_ADMIN"), initialOwner);
        roleManager.checkRole(keccak256("CHAIN_ADMIN"), initialOwner);

        roleManager.grantRole(keccak256("CHAIN_ADMIN"), chainAdmin);
        roleManager.checkRole(keccak256("CHAIN_ADMIN"), chainAdmin);

        roleManager.grantRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            twineOperationsHandler
        );
        roleManager.checkRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            twineOperationsHandler
        );

        roleManager.grantRole(keccak256("TWINE_GATEWAYS"), centralizedETHGatewayAddress);
        roleManager.checkRole(keccak256("TWINE_GATEWAYS"), centralizedETHGatewayAddress);

        roleManager.grantRole(
            keccak256("TWINE_GATEWAYS"),
            centralizedCustomERC20GatewayAddress
        );
        roleManager.checkRole(
            keccak256("TWINE_GATEWAYS"),
            centralizedCustomERC20GatewayAddress
        );

        // CentralizedETHGateway setup
        centralizedETHGateway.setRoleManagerAddress(roleManagerAddress);
        centralizedETHGateway.setGatewayRouter(centralizedGatewayRouterAddress);
        centralizedETHGateway.setTwineMessenger(centralizedTwineMessengerAddress);
        centralizedETHGateway.setL2TokenAddress(twineEthTokenAddress);
        centralizedETHGateway.setChainId(chainId);

        // CentralizedGatewayRouter setup
        centralizedGatewayRouter.setRoleManagerAddress(roleManagerAddress);
        centralizedGatewayRouter.setETHGateway(centralizedETHGatewayAddress);
        centralizedGatewayRouter.setDefaultERC20Gateway(centralizedCustomERC20GatewayAddress);

        address[] memory tokens = new address[](2);
        address[] memory gateways = new address[](2);
        tokens[0] = centralizedFauxCoinAddress;
        tokens[1] = centralizedEthSolTokenAddress;

        gateways[0] = centralizedCustomERC20GatewayAddress;
        gateways[1] = centralizedCustomERC20GatewayAddress;
        centralizedGatewayRouter.setERC20Gateway(tokens, gateways);

        //L1TwineMessenger setup
        centralizedTwineMessenger.setRoleManager(roleManagerAddress);
        centralizedTwineMessenger.setCounterpartMessenger(twineTwineMessengerAddress);
        centralizedTwineMessenger.setGatewayAddress(
            centralizedETHGatewayAddress,
            centralizedCustomERC20GatewayAddress
        );

        //L1CustomERC20Gateway setup
        centralizedCustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        centralizedCustomERC20Gateway.setGatewayRouter(centralizedGatewayRouterAddress);
        centralizedCustomERC20Gateway.setTwineMessenger(centralizedTwineMessengerAddress);
        centralizedCustomERC20Gateway.updateTokenMapping(
            centralizedFauxCoinAddress,
            twineFauxCoinAddress
        );
        centralizedCustomERC20Gateway.updateTokenMapping(
            centralizedEthSolTokenAddress,
            twineSolTokenAddress
        );

        centralizedCustomERC20Gateway.setChainId(chainId);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
