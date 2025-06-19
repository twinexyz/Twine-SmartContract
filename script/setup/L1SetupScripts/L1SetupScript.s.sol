// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageQueue} from "../../../src/L1/rollup/L1MessageQueue.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";
import {L1CustomERC20Gateway} from "../../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract L1SetupScript is Script {
    MockERC20 token;
    TwineChain twineChain;
    RoleManager roleManager;
    L1ETHGateway l1ETHGateway;
    L1MessageQueue l1MessageQueue;
    L1GatewayRouter l1GatewayRouter;
    L1TwineMessenger l1TwineMessenger;
    L1CustomERC20Gateway l1CustomERC20Gateway;

    uint64 chainId;
    bytes32 executionVkey;
    bytes32 inclusionVKey;
    bytes32 withdrawalVKey;
    address tokenAddress;
    address verifierAddress;
    address twineChainAddress;
    address roleManagerAddress;
    address l1ETHGatewayAddress;
    address l1ERC20TokenAddress;
    address l2ERC20TokenAddress;
    address l2ETHGatewayAddress;
    address l1MessageQueueAddress;
    address l1GatewayRouterAddress;
    address l1XERC20GatewayAddress;
    address twineOperationsHandler;
    address l1TwineMessengerAddress;
    address l2TwineMessengerAddress;
    address l1CustomERC20GatewayAddress;
    address l2CustomERC20GatewayAddress;
    address l2ETHTokenAddress;

    function setUp() public {
        string memory deployedL1Json = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        string memory deployedL2Json = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1RoleManager"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1ETHGateway"
        );

        l1ERC20TokenAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".FauxCoin"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1CustomERC20Gateway"
        );

        twineChainAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".TwineChain"
        );

        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1GatewayRouter"
        );

        l1XERC20GatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1XERC20Gateway"
        );

        l1MessageQueueAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1MessageQueue"
        );

        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1TwineMessenger"
        );

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2TwineMessenger"
        );

        verifierAddress = vm.parseJsonAddress(deployedL1Json, ".Verifier");

        executionVkey = vm.parseJsonBytes32(
            deployedL1Json,
            ".executionVkey"
        );
        inclusionVKey = vm.parseJsonBytes32(
            deployedL1Json,
            ".inclusionVkey"
        );
        withdrawalVKey = vm.parseJsonBytes32(
            deployedL1Json,
            ".withdrawalVkey"
        );

        l2ERC20TokenAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".FauxCoin"
        );

        l2ETHTokenAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".ETHToken"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2CustomERC20Gateway"
        );

        l2ETHGatewayAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2ETHGateway"
        );

        twineChain = TwineChain(twineChainAddress);
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );

        roleManager = RoleManager(roleManagerAddress);
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
        token = MockERC20(tokenAddress);
        chainId = 17000; //holesky chain Id
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

        roleManager.grantRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            twineOperationsHandler
        );
        roleManager.checkRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            twineOperationsHandler
        );

        //TwineChain setup
        twineChain.setRoleManagerAddress(roleManagerAddress);
        twineChain.setChainId(chainId);
        twineChain.setMessengerQueueAddress(l1MessageQueueAddress);
        twineChain.setVeriferAddress(verifierAddress);
        twineChain.setProgramVKey(executionVkey, inclusionVKey, withdrawalVKey);
        twineChain.setGatewayAddress(
            l1ETHGatewayAddress,
            l1CustomERC20GatewayAddress
        );

        //L1ETHGateway setup
        l1ETHGateway.setRoleManagerAddress(roleManagerAddress);
        l1ETHGateway.setGatewayRouter(l1GatewayRouterAddress);
        l1ETHGateway.setTwineMessenger(l1TwineMessengerAddress);
        l1ETHGateway.setL2TokenAddress(l2ETHTokenAddress);
        l1ETHGateway.setChainId(chainId);

        //L1MessageQueue setup
        l1MessageQueue.setRoleManager(roleManagerAddress);
        l1MessageQueue.setChainId(chainId);
        l1MessageQueue.setMessengerAddress(l1TwineMessengerAddress);
        l1MessageQueue.setMessageQueueProxy(l1MessageQueueAddress);

        //L1GatewayRouter setup
        l1GatewayRouter.setRoleManagerAddress(roleManagerAddress);
        l1GatewayRouter.setETHGateway(l1ETHGatewayAddress);
        l1GatewayRouter.setDefaultERC20Gateway(l1CustomERC20GatewayAddress);

        address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);
        tokens[0] = l1ERC20TokenAddress;
        gateways[0] = l1CustomERC20GatewayAddress;
        l1GatewayRouter.setERC20Gateway(tokens, gateways);

        //L1TwineMessenger setup
        l1TwineMessenger.setRoleManager(roleManagerAddress);
        l1TwineMessenger.setRollupAddress(twineChainAddress);
        l1TwineMessenger.setMessengerQueueAddress(l1MessageQueueAddress);
        l1TwineMessenger.setCounterpartMessenger(l2TwineMessengerAddress);

        //L1CustomERC20Gateway setup
        l1CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l1CustomERC20Gateway.setGatewayRouter(l1GatewayRouterAddress);
        l1CustomERC20Gateway.setTwineMessenger(l1TwineMessengerAddress);
        l1CustomERC20Gateway.updateTokenMapping(
            l1ERC20TokenAddress,
            l2ERC20TokenAddress
        );
        l1CustomERC20Gateway.setChainId(chainId);

        console.logBytes32(twineChain.executionVKey());

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
