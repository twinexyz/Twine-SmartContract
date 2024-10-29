// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "./mocks/MockERC20.sol";
import {MockXERC20} from "./mocks/MockXERC20.sol";
import {MockLockBox} from "./mocks/MockLockBox.sol";
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";
import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {L1GatewayRouter, L1GatewayRouter} from "../L1/gateways/L1GatewayRouter.sol";
import {L1MessageQueue} from "../L1/rollup/L1MessageQueue.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
import {IXERC20Lockbox} from "../libraries/token/IXERC20Lockbox.sol";
import {IL1XERC20Gateway, L1XERC20Gateway} from "../L1/gateways/L1XERC20Gateway.sol";
import {TwineChain} from "../L1/rollup/TwineChain.sol";
import {IL2XERC20Gateway, L2XERC20Gateway} from "../L2/gateways/L2XERC20Gateway.sol";

contract L1XERC20GatewayTest is Test {
    L1XERC20Gateway private gateway;
    L1GatewayRouter private router;
    L2XERC20Gateway private counterpartGateway;
    RoleManager private roleManager;
    MockERC20 l1Token;
    MockXERC20 l1XToken;
    MockXERC20 l2XToken;
    MockLockBox lockBox;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    L1TwineMessenger private l1Messenger;
    L2TwineMessenger private l2Messenger;
    L1MessageQueue private messageQueue;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    TwineChain private rollup;

    function setUp() public {
        vm.startPrank(initialOwner);
        // Deploy tokens
        l1Token = new MockERC20("Mock L1", "ML1");
        l1XToken = new MockXERC20("Mock XL1", "MXL1");
        l2XToken = new MockXERC20("Mock XL2", "MXL2");
        l1Token.mint(initialOwner, 10000000);

        lockBox = new MockLockBox(address(l1XToken), address(l1Token), false);

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
            abi.encodeCall(L1GatewayRouter.initialize, (address(0), address(0)))
        );
        router = L1GatewayRouter(L1GatewayRouterAddress);

        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol",
            msg.sender,
            abi.encodeCall(L1MessageQueue.initialize, (address(0),0,address(roleManager)))
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
            abi.encodeCall(TwineChain.initialize, (address(0), address(0))) // Example initial value
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


        //setup customErc20 Gateway
        address L1XERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1XERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1XERC20Gateway.initialize,
                (address(0), address(router), address(l1Messenger))
            )
        );
        gateway = L1XERC20Gateway(L1XERC20GatewayAddress);
        l1XToken.setLimits(address(gateway), 1000000, 1000000);
        l1XToken.setLimits(address(lockBox), 1000000, 1000000);
        l1XToken.setLockbox(address(lockBox));

        address[] memory tokens = new address[](2);
        address[] memory gateways = new address[](2);

        tokens[0] = address(l1Token);
        gateways[0] = address(gateway);
        tokens[1] = address(l1XToken);
        gateways[1] = address(gateway);
        //setup gateway in router;
        router.setERC20Gateway(tokens, gateways);
        router.setAddress(address(gateway), address(gateway));
        L1XERC20Gateway.XTokenConfig memory xConfig = L1XERC20Gateway
            .XTokenConfig({
                l2Token: address(l2XToken),
                l1xToken: address(l1XToken),
                l2xToken: address(l2XToken),
                l1LockBox: address(lockBox),
                l2LockBox: address(lockBox)
            });
        gateway.updateTokenMapping(address(l1Token), xConfig);
        gateway.updateTokenMapping(address(l1XToken), xConfig);
        gateway.setRoleManagerAddress(address(roleManager));
        vm.startPrank(initialOwner);
        messageQueue.setAddress(address(l1Messenger));
    }

    function testDepositOfERC20() public {
        vm.startPrank(initialOwner);
        assertEq(l1Token.balanceOf(initialOwner),10000000);
        l1Token.approve(address(gateway), 100000);
        l1Token.approve(address(router), 100000);
        router.depositXERC20{value: 0}(address(l1Token), address(this), 10, 0);
        assertEq(l1Token.balanceOf(initialOwner),9999990);
    }

    function testDepositOfXERC20() public {

        vm.startPrank(initialOwner);
        assertEq(l1Token.balanceOf(initialOwner),10000000);
        l1Token.approve(address(lockBox), 100000);
        IXERC20Lockbox(address(lockBox)).depositTo(initialOwner, 20);
        assertEq(l1Token.balanceOf(initialOwner),9999980);
        l1XToken.approve(address(gateway), 100000);
        l1XToken.approve(address(router), 100000);
        assertEq(l1XToken.balanceOf(initialOwner),20);
        router.depositXERC20{value: 0}(address(l1XToken), address(this), 10, 0);
        gateway.depositXERC20(address(l1XToken), address(this), 10,10);
        assertEq(l1XToken.balanceOf(initialOwner),0);
      
    }

    function testWithdrawOfERC20() public {
        assertEq(l1Token.balanceOf(initialOwner),10000000);
        l1Token.approve(address(gateway), 100000);
        gateway.depositXERC20(address(l1Token), address(this), 10,  10);
        assertEq(l1Token.balanceOf(initialOwner),9999990);
        assertEq(l1Token.balanceOf(address(lockBox)),10);
        gateway.finalizeWithdrawXERC20(
            address(l1Token),
            address(l2XToken),
            initialOwner,
            initialOwner,
            10,
            new bytes(0)
        );
        assertEq(l1Token.balanceOf(address(lockBox)),0);
        assertEq(l1Token.balanceOf(initialOwner),10000000);
    }

     function testWithdrawOfXERC20() public {
        assertEq(l1XToken.balanceOf(initialOwner),0);
        gateway.finalizeWithdrawXERC20(
            address(l1XToken),
            address(l2XToken),
            initialOwner,
            initialOwner,
            10,
            new bytes(0)
        );
        assertEq(l1XToken.balanceOf(initialOwner),10);
    }
}
