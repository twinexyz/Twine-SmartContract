// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "./mocks/MockERC20.sol";
import {L2MsgExecutor} from "../L2/L2MsgExecutor.sol";
import {TwineChain} from "../L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";
import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {L1MessageHandler} from "../L1/rollup/L1MessageHandler.sol";
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
    L1MessageHandler private messageHandler;
    L1TwineMessenger private l1Messenger;
    L2TwineMessenger private l2Messenger;
    L1CustomERC20Gateway private gateway;
    L2CustomERC20Gateway private counterpartGateway;

    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_CHAIN = keccak256("TWINE_CHAIN");
    bytes32 public constant TWINE_GATEWAYS = keccak256("TWINE_GATEWAYS");

    error ZeroAddress();

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
            abi.encodeCall(
                L1GatewayRouter.initialize,
                (address(0), address(0), address(roleManager))
            )
        );
        router = L1GatewayRouter(L1GatewayRouterAddress);

        address L1MessageHandlerAddress = Upgrades.deployTransparentProxy(
            "L1MessageHandler.sol",
            msg.sender,
            abi.encodeCall(
                L1MessageHandler.initialize,
                (0, address(0), address(roleManager))
            )
        );
        messageHandler = L1MessageHandler(L1MessageHandlerAddress);

        address L2MessageExecutorAddress = Upgrades.deployTransparentProxy(
            "L2MsgExecutor.sol",
            initialOwner,
            abi.encodeCall(L2MsgExecutor.initialize, (roleManagerAddress))
        );

        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (0, address(0), address(roleManager),L2MessageExecutorAddress)
            )
        );

        l2Messenger = L2TwineMessenger(L2TwineMessengerAddress);

        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            msg.sender,
            abi.encodeCall(
                TwineChain.initialize,
                (address(0), address(0), address(roleManager))
            )
        );

        rollup = TwineChain(TwineChainAddress);

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (
                    address(l2Messenger),
                    address(messageHandler),
                    address(0),
                    address(roleManager)
                )
            )
        );

        l1Messenger = L1TwineMessenger(L1TwineMessengerAddress);

        //setup customErc20 Gateway
        address L1CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1CustomERC20Gateway.initialize,
                (
                    address(router),
                    address(l1Messenger),
                    address(roleManager),
                    1700
                )
            )
        );

        gateway = L1CustomERC20Gateway(L1CustomERC20GatewayAddress);
        roleManager.grantRole(TWINE_GATEWAYS, address(gateway));

        address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);

        tokens[0] = address(l1Token);
        gateways[0] = address(gateway);
        //setup gateway in router;
        vm.startPrank(initialOwner);
        router.setERC20Gateway(tokens, gateways);
        router.setETHGateway(address(gateway));
        router.setDefaultERC20Gateway(address(gateway));
        gateway.setRoleManagerAddress(address(roleManager));
        messageHandler.setMessengerAddress(address(l1Messenger));
        vm.stopPrank();
    }
    function testSetRoleManagerAddress() public {
        vm.startPrank(initialOwner);
        address newRoleManager = address(0x123);
        gateway.setRoleManagerAddress(newRoleManager);
        assertEq(gateway.roleManager(), newRoleManager);
        vm.stopPrank();
    }

    function testSetRoleManagerAddressZeroAddress() public {
        vm.startPrank(initialOwner);
        vm.expectRevert(ZeroAddress.selector);
        gateway.setRoleManagerAddress(address(0));
        vm.stopPrank();
    }

    function testSetRoleManagerAddressNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        gateway.setRoleManagerAddress(address(0x456));
        vm.stopPrank();
    }

    function testSetGatewayRouter() public {
        vm.startPrank(initialOwner);
        address newRouter = address(0x123);
        gateway.setGatewayRouter(newRouter);
        assertEq(gateway.gatewayRouter(), newRouter);
        vm.stopPrank();
    }

    function testSetGatewayRouterZeroAddress() public {
        vm.startPrank(initialOwner);
        vm.expectRevert(ZeroAddress.selector);
        gateway.setGatewayRouter(address(0));
        vm.stopPrank();
    }

    function testSetGatewayRouterNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        gateway.setGatewayRouter(address(0x456));
        vm.stopPrank();
    }

    function testSetTwineMessenger() public {
        vm.startPrank(initialOwner);
        address newMessenger = address(0x123);
        gateway.setTwineMessenger(newMessenger);
        assertEq(gateway.messenger(), newMessenger);
        vm.stopPrank();
    }

    function testSetTwineMessengerZeroAddress() public {
        vm.startPrank(initialOwner);
        vm.expectRevert(ZeroAddress.selector);
        gateway.setTwineMessenger(address(0));
        vm.stopPrank();
    }

    function testSetTwineMessengerNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        gateway.setTwineMessenger(address(0x456));
        vm.stopPrank();
    }

    function testSetChainId() public {
        vm.startPrank(initialOwner);
        uint64 newChainId = 2;
        gateway.setChainId(newChainId);
        assertEq(gateway.chainId(), newChainId);
        vm.stopPrank();
    }

    function testSetChainIdNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        gateway.setChainId(2);
        vm.stopPrank();
    }

    function testUpdateTokenMapping() public {
        vm.startPrank(initialOwner);
        gateway.updateTokenMapping(address(l1Token), address(l2Token));
        vm.stopPrank();
        assertEq(gateway.getL2ERC20Address(address(l1Token)), address(l2Token));
    }

    function testUpdateTokenMappingZeroValueNotAllowed() public {
        vm.startPrank(initialOwner);
        vm.expectRevert();
        gateway.updateTokenMapping(address(l1Token), address(0));
        vm.stopPrank();
    }
    function testUpdateTokenMappingNonAdminReverts() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        gateway.updateTokenMapping(address(l1Token), address(0));
        vm.stopPrank();
    }

    //testing the commit and finalize batch, commit and finalize transaction, finalize token withdrawal
    function testDepositERC20() public {
        vm.startPrank(initialOwner);
        gateway.updateTokenMapping(address(l1Token), address(l2Token));
        assertEq(l1Token.balanceOf(initialOwner), 100000);
        l1Token.approve(address(gateway), 100000);
        l1Token.approve(address(router), 100000);
        console.log("gateway:", router.getERC20Gateway(address(l1Token)));
        vm.deal(initialOwner, 10 ether);
        router.depositERC20{value: 1 ether}(
            address(l1Token),
            address(this),
            10,
            0
        );
        gateway.depositERC20{value: 1 ether}(
            address(l1Token),
            address(this),
            10,
            0
        );
        assertEq(l1Token.balanceOf(initialOwner), 99980);
    }

    function testfinalizeTokenWithdrawal() public {
        vm.startPrank(initialOwner);
        gateway.updateTokenMapping(address(l1Token), address(l2Token));
        assertEq(l1Token.balanceOf(initialOwner), 100000);
        l1Token.approve(address(gateway), 100000);
        l1Token.approve(address(router), 100000);
        vm.deal(initialOwner, 10 ether);
        router.depositERC20{value: 1}(address(l1Token), address(this), 10, 0);
        assertEq(l1Token.balanceOf(initialOwner), 99990);
        roleManager.grantRole(TWINE_CHAIN, initialOwner);
        gateway.finalizeTokenWithdrawal(
            addressToString(address(l1Token)),
            addressToString(address(l2Token)),
            addressToString(initialOwner),
            "10",
            1
        );
        assertEq(l1Token.balanceOf(initialOwner), 100000);
    }

    function testforcedWithdrawal() public {
        vm.startPrank(initialOwner);
        gateway.updateTokenMapping(address(l1Token), address(l2Token));
        vm.deal(initialOwner, 1 ether);
        gateway.forcedWithdrawalERC20(
            address(l1Token),
            address(l2Token),
            initialOwner,
            100000,
            10,
            new bytes(0)
        );
        assertEq(messageHandler.messageIndex(), 1);
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
