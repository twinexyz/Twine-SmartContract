// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "./mocks/MockERC20.sol";
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";
import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {IL1GatewayRouter, L1GatewayRouter} from "../L1/gateways/L1GatewayRouter.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
import {L1MessageQueue} from "../L1/rollup/L1MessageQueue.sol";
import {IL1ETHGateway, L1ETHGateway} from "../L1/gateways/L1ETHGateway.sol";
import {TwineChain} from "../L1/rollup/TwineChain.sol";
import {IL2ETHGateway, L2ETHGateway} from "../L2/gateways/L2ETHGateway.sol";

contract L1ETHGatewayTest is Test {
    L1ETHGateway private gateway;
    L1GatewayRouter private router;
    L2ETHGateway private counterpartGateway;
    RoleManager private roleManager;
    MockERC20 l1Token;
    MockERC20 l2Token;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    L1TwineMessenger private l1Messenger;
    L2TwineMessenger private l2Messenger;
    L1MessageQueue private messageQueue;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    TwineChain private rollup;

    function setUp() public {
        vm.startPrank(initialOwner);
        deal(initialOwner, 10 ether);

        //setup the rolemanager
        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );
        roleManager = RoleManager(roleManagerAddress);
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.checkRole(CHAIN_ADMIN, initialOwner);

        address L1GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L1GatewayRouter.sol",
            msg.sender,
            abi.encodeCall(L1GatewayRouter.initialize, (address(0), address(0),address(roleManager)))
        );
        router = L1GatewayRouter(L1GatewayRouterAddress);

        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol",
            msg.sender,
            abi.encodeCall(
                L1MessageQueue.initialize,
                (address(0), 0, address(roleManager))
            )
        );
        messageQueue = L1MessageQueue(L1MessageQueueAddress);

        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (address(0), address(0))
            )
        );

        l2Messenger = L2TwineMessenger(L2TwineMessengerAddress);

        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            msg.sender,
            abi.encodeCall(TwineChain.initialize, (address(0), address(0)))
        );

        rollup = TwineChain(TwineChainAddress);

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (address(l2Messenger), address(messageQueue), address(0))
            )
        );

        l1Messenger = L1TwineMessenger(L1TwineMessengerAddress);

        //setup ETH Gateway
        address L1ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L1ETHGateway.sol",
            msg.sender,
            abi.encodeCall(
                L1ETHGateway.initialize,
                (address(0), address(router), address(l1Messenger))
            )
        );
        gateway = L1ETHGateway(L1ETHGatewayAddress);

       
        //setup gateway in router;
        vm.startPrank(initialOwner);
        router.setAddress(address(gateway), address(gateway));
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.checkRole(CHAIN_ADMIN, initialOwner);
        gateway.setRoleManagerAddress(address(roleManager));
        messageQueue.setAddress(address(l1Messenger));
        vm.stopPrank();

    }

    function testDepositETH() public {
        vm.startPrank(initialOwner);
        console.log("Initial owner Before ", address(gateway).balance);
        uint256 depositAmount = 1 ether;
        router.depositETH{value: depositAmount}(initialOwner, depositAmount, 0);
        gateway.depositETH{value: depositAmount}(
            initialOwner,
            depositAmount,
            0
        );
        assertEq(address(l1Messenger).balance,2 ether);
    }
}
