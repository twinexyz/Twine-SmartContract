// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "./mocks/MockERC20.sol";
import {TwineChain} from "../L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";
import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {L1MessageQueue} from "../L1/rollup/L1MessageQueue.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
import {IL1GatewayRouter, L1GatewayRouter} from "../L1/gateways/L1GatewayRouter.sol";
import {IL1ERC20Gateway, L1CustomERC20Gateway} from "../L1/gateways/L1CustomERC20Gateway.sol";
import {IL2ERC20Gateway, L2CustomERC20Gateway} from "../L2/gateways/L2CustomERC20Gateway.sol";

contract L1CustomERC20GatewayTest is Test {
    MockERC20 l1Token;
    MockERC20 l2Token;
    TwineChain private rollup;
    L1GatewayRouter private router;
    RoleManager private roleManager;
    L1MessageQueue private messageQueue;
    L1TwineMessenger private l1Messenger;
    L2TwineMessenger private l2Messenger;
    L1CustomERC20Gateway private gateway;
    L2CustomERC20Gateway private counterpartGateway;


    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");

    function setUp() public {
        vm.startPrank(initialOwner);
        // Deploy tokens
        l1Token = new MockERC20("Mock L1", "ML1");
        l2Token = new MockERC20("Mock L2", "ML2");
        l1Token.mint(initialOwner, 100000);

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
            abi.encodeCall(L1MessageQueue.initialize, (0,address(0),address(roleManager)))
        );
        messageQueue = L1MessageQueue(L1MessageQueueAddress);

        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (0,address(0), address(roleManager))
            ) 
        );

        l2Messenger = L2TwineMessenger(L2TwineMessengerAddress);

        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            msg.sender,
            abi.encodeCall(TwineChain.initialize, (address(0), address(0),address(roleManager))) 
        );

        rollup = TwineChain(TwineChainAddress);

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (address(l2Messenger), address(messageQueue), address(0),address(0))
            )
        );

        l1Messenger = L1TwineMessenger(L1TwineMessengerAddress);

        //setup customErc20 Gateway
        address L1CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1CustomERC20Gateway.initialize,
                (address(0), address(router), address(l1Messenger),address(roleManager))
            )
        );

        gateway = L1CustomERC20Gateway(L1CustomERC20GatewayAddress);

        address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);

        tokens[0] = address(l1Token);
        gateways[0] = address(gateway);
        //setup gateway in router;
        vm.startPrank(initialOwner);
        router.setERC20Gateway(tokens, gateways);
        router.setAddress(address(gateway), address(gateway));
        gateway.setRoleManagerAddress(address(roleManager));
        messageQueue.setMessengerAddress(address(l1Messenger));
        vm.stopPrank();
    }

    function testDepositERC20() public {
        vm.startPrank(initialOwner);
        gateway.updateTokenMapping(address(l1Token), address(l2Token));
        assertEq(l1Token.balanceOf(initialOwner),100000);
        l1Token.approve(address(gateway), 100000);
        l1Token.approve(address(router), 100000);
        router.depositERC20{value: 0}(address(l1Token), address(this), 10, 0);
        assertEq(l1Token.balanceOf(initialOwner),99990);
    }

    function testWithdrawERC20() public {
        vm.startPrank(initialOwner);
        gateway.updateTokenMapping(address(l1Token), address(l2Token));
        assertEq(l1Token.balanceOf(initialOwner),100000);
        l1Token.approve(address(gateway), 100000);
        l1Token.approve(address(router), 100000);
        router.depositERC20{value: 0}(address(l1Token), address(this), 10, 0);
        assertEq(l1Token.balanceOf(initialOwner),99990);
        gateway.finalizeWithdrawERC20(
            address(l1Token),
            address(l2Token),
            initialOwner,
            initialOwner,
            10,
            new bytes(0)
        );
        assertEq(l1Token.balanceOf(initialOwner),100000);
    }
}