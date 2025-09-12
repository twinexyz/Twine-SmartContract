// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageHandler} from "../../../src/L1/rollup/L1MessageHandler.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";
import {L1CustomERC20Gateway} from "../../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract L1SetupScript is Script {
    // Contracts
    TwineChain twineChain;
    RoleManager roleManager;
    L1ETHGateway l1ETHGateway;
    L1MessageHandler l1MessageHandler;
    L1GatewayRouter l1GatewayRouter;
    L1TwineMessenger l1TwineMessenger;
    L1CustomERC20Gateway l1CustomERC20Gateway;

    // Setup Values
    uint64 chainId;
    address chainAdmin;
    bytes32 refundVKey;
    bytes32 finalizeVKey;
    bytes32 l2WithdrawalVkey;
    bytes32 forcedWithdrawalVKey;
    address twineOperationsHandler;

    // l2 Contract Addresses
    address l2FauxCoinAddress;
    address l2SolTokenAddress;
    address l2EthTokenAddress;
    address l2ETHGatewayAddress;
    address l2TwineMessengerAddress;
    address l2CustomERC20GatewayAddress;

    // L1 Contract Addresses
    address verifierAddress;
    address l1FauxCoinAddress;
    address twineChainAddress;
    address roleManagerAddress;
    address l1ETHGatewayAddress;
    address l1EthSolTokenAddress;
    address l1GatewayRouterAddress;
    address l1XERC20GatewayAddress;
    address l1MessageHandlerAddress;
    address l1TwineMessengerAddress;
    address l1CustomERC20GatewayAddress;

    function setUp() public {
        // <--------------------------- Read Json Files ---------------------------->
        string memory deployedL1Json = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        string memory deployedL2Json = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        string memory L1SetupJson = vm.readFile("./script/utils/setupValues.json");

        // <-------------------- Deployed L1 Contract Addresses -------------------->
        roleManagerAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1RoleManager"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1ETHGateway"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1CustomERC20Gateway"
        );

        twineChainAddress = vm.parseJsonAddress(deployedL1Json, ".TwineChain");

        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1GatewayRouter"
        );

        l1XERC20GatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1XERC20Gateway"
        );

        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1MessageHandler"
        );

        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1TwineMessenger"
        );

        l1FauxCoinAddress = vm.parseJsonAddress(deployedL1Json, ".FauxCoin");

        l1EthSolTokenAddress = vm.parseJsonAddress(deployedL1Json, ".EthSol");

        // <-------------------- Deployed L2 Contract Addresses -------------------->

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2TwineMessenger"
        );

        verifierAddress = vm.parseJsonAddress(deployedL1Json, ".Verifier");

        l2FauxCoinAddress = vm.parseJsonAddress(deployedL2Json, ".FauxCoin");
        l2SolTokenAddress = vm.parseJsonAddress(deployedL2Json, ".SolToken");
        l2EthTokenAddress = vm.parseJsonAddress(deployedL2Json, ".ETHToken");
        
        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2CustomERC20Gateway"
        );

        l2ETHGatewayAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2ETHGateway"
        );

        // <-------------------- L1 Contracts -------------------->

        twineChain = TwineChain(twineChainAddress);
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );
        roleManager = RoleManager(roleManagerAddress);
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);

        // <--------------- Setup Values --------------->

        refundVKey = vm.parseJsonBytes32(deployedL1Json, ".refundVkey");
        finalizeVKey = vm.parseJsonBytes32(deployedL1Json, ".finalizeVkey");
        forcedWithdrawalVKey = vm.parseJsonBytes32(deployedL1Json, ".forcedWithdrawalVkey");
        l2WithdrawalVkey = vm.parseJsonBytes32(deployedL1Json, ".l2WithdrawalVkey");

        chainId = uint64(vm.parseJsonUint(L1SetupJson, ".ChainIdEth"));
        chainAdmin = vm.parseJsonAddress(L1SetupJson, ".L1ChainAdmin");
        twineOperationsHandler = vm.parseJsonAddress(
            L1SetupJson,
            ".L1TwineOperationHandler"
        );
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
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

        roleManager.grantRole(keccak256("TWINE_GATEWAYS"), l1ETHGatewayAddress);
        roleManager.checkRole(keccak256("TWINE_GATEWAYS"), l1ETHGatewayAddress);

        roleManager.grantRole(
            keccak256("TWINE_GATEWAYS"),
            l1CustomERC20GatewayAddress
        );
        roleManager.checkRole(
            keccak256("TWINE_GATEWAYS"),
            l1CustomERC20GatewayAddress
        );

        roleManager.grantRole(keccak256("TWINE_CHAIN"), twineChainAddress);
        roleManager.checkRole(keccak256("TWINE_CHAIN"), twineChainAddress);

        //TwineChain setup
        twineChain.setRoleManagerAddress(roleManagerAddress);
        twineChain.setChainId(chainId);
        twineChain.setMessageHandlerAddress(l1MessageHandlerAddress);
        twineChain.setVeriferAddress(verifierAddress);
        twineChain.setProgramVKey(finalizeVKey, refundVKey, forcedWithdrawalVKey, l2WithdrawalVkey);
        twineChain.setGatewayAddress(
            l1ETHGatewayAddress,
            l1CustomERC20GatewayAddress
        );

        //L1ETHGateway setup
        l1ETHGateway.setRoleManagerAddress(roleManagerAddress);
        l1ETHGateway.setGatewayRouter(l1GatewayRouterAddress);
        l1ETHGateway.setTwineMessenger(l1TwineMessengerAddress);
        l1ETHGateway.setL2TokenAddress(l2EthTokenAddress);
        l1ETHGateway.setChainId(chainId);

        //L1MessageHandler setup
        l1MessageHandler.setRoleManager(roleManagerAddress);
        l1MessageHandler.setChainId(chainId);
        l1MessageHandler.setMessengerAddress(l1TwineMessengerAddress);
        l1MessageHandler.setMessageHandlerProxy(l1MessageHandlerAddress);

        //L1GatewayRouter setup
        l1GatewayRouter.setRoleManagerAddress(roleManagerAddress);
        l1GatewayRouter.setETHGateway(l1ETHGatewayAddress);
        l1GatewayRouter.setDefaultERC20Gateway(l1CustomERC20GatewayAddress);

        address[] memory tokens = new address[](2);
        address[] memory gateways = new address[](2);
        tokens[0] = l1FauxCoinAddress;
        tokens[1] = l1EthSolTokenAddress;

        gateways[0] = l1CustomERC20GatewayAddress;
        gateways[1] = l1CustomERC20GatewayAddress;
        l1GatewayRouter.setERC20Gateway(tokens, gateways);

        //L1TwineMessenger setup
        l1TwineMessenger.setRoleManager(roleManagerAddress);
        l1TwineMessenger.setRollupAddress(twineChainAddress);
        l1TwineMessenger.setMessageHandlerAddress(l1MessageHandlerAddress);
        l1TwineMessenger.setCounterpartMessenger(l2TwineMessengerAddress);

        //L1CustomERC20Gateway setup
        l1CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l1CustomERC20Gateway.setGatewayRouter(l1GatewayRouterAddress);
        l1CustomERC20Gateway.setTwineMessenger(l1TwineMessengerAddress);
        l1CustomERC20Gateway.updateTokenMapping(
            l1FauxCoinAddress,
            l2FauxCoinAddress
        );
        l1CustomERC20Gateway.updateTokenMapping(
            l1EthSolTokenAddress,
            l2SolTokenAddress
        );

        l1CustomERC20Gateway.setChainId(chainId);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
