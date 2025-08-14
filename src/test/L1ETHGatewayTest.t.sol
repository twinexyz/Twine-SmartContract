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
import {IL2ETHGateway, L2ETHGateway} from "../L2/gateways/L2ETHGateway.sol";
import {IL1ETHGateway, L1ETHGateway} from "../L1/gateways/L1ETHGateway.sol";
import {IL1GatewayRouter, L1GatewayRouter} from "../L1/gateways/L1GatewayRouter.sol";

contract L1ETHGatewayTest is Test {
    MockERC20 l1Token;
    MockERC20 l2Token;
    TwineChain private twineChain;
    L1ETHGateway private gateway;
    L1GatewayRouter private router;
    RoleManager private roleManager;
    L1MessageHandler private messageQueue;
    L1TwineMessenger private l1TwineMessenger;
    L2TwineMessenger private l2Messenger;
    L2ETHGateway private counterpartGateway;

    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_CHAIN = keccak256("TWINE_CHAIN");
    bytes32 public constant TWINE_GATEWAYS = keccak256("TWINE_GATEWAYS");

    function setUp() public {
        vm.startPrank(initialOwner);
        deal(initialOwner, 10 ether);
        l2Token = new MockERC20("Mock L2", "ML2");

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

        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageHandler.sol",
            msg.sender,
            abi.encodeCall(
                L1MessageHandler.initialize,
                (0, address(0), address(roleManager))
            )
        );
        messageQueue = L1MessageHandler(L1MessageQueueAddress);

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
                (0, address(0), address(0),L2MessageExecutorAddress)
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

        twineChain = TwineChain(TwineChainAddress);

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (
                    address(l2Messenger),
                    address(messageQueue),
                    address(0),
                    address(roleManager)
                )
            )
        );

        l1TwineMessenger = L1TwineMessenger(L1TwineMessengerAddress);

        //setup ETH Gateway
        address L1ETHGatewayAddress = Upgrades.deployTransparentProxy(
            "L1ETHGateway.sol",
            msg.sender,
            abi.encodeCall(
                L1ETHGateway.initialize,
                (
                    address(router),
                    address(l1TwineMessenger),
                    address(roleManager),
                    1700
                )
            )
        );
        gateway = L1ETHGateway(L1ETHGatewayAddress);
        roleManager.grantRole(TWINE_GATEWAYS, address(gateway));
        gateway.setL2TokenAddress(address(l2Token));

        //setup gateway in router;
        vm.startPrank(initialOwner);
        router.setETHGateway(address(gateway));
        router.setDefaultERC20Gateway(address(gateway));
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.checkRole(CHAIN_ADMIN, initialOwner);
        gateway.setRoleManagerAddress(address(roleManager));
        messageQueue.setMessengerAddress(address(l1TwineMessenger));
        vm.stopPrank();
    }

    function testSetL2TokenAddressNonAdminReverts() public {
        address nonAdminUser = address(0x123);
        address l2TokenAddress = address(0x234);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        gateway.setL2TokenAddress(l2TokenAddress);
    }

    function testSetL2TokenAddressZeroAddressNotAllowed() public {
        vm.startPrank(initialOwner);
        vm.expectRevert();
        gateway.setL2TokenAddress(address(0));
    }

    function testSetL2TokenAddress() public {
        vm.startPrank(initialOwner);
        address l2TokenAddress = address(0x123);
        gateway.setL2TokenAddress(l2TokenAddress);
        assertEq(gateway.l2TokenAddress(), l2TokenAddress);
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
        assertEq(address(gateway).balance, 2 ether);
    }

    function testfinalizeTokenWithdrawal() public {
        vm.startPrank(initialOwner);
        uint256 depositAmount = 1 ether;
        gateway.setL2TokenAddress(address(l2Token));
        gateway.depositETH{value: depositAmount}(
            initialOwner,
            depositAmount,
            0
        );
        roleManager.grantRole(TWINE_CHAIN, initialOwner);
        gateway.finalizeTokenWithdrawal(
            addressToString(address(l1Token)),
            addressToString(address(l2Token)),
            addressToString(initialOwner),
            "10000000000",
            1
        );
        assertEq(address(gateway).balance, 999999990000000000);
        vm.stopPrank();
    }

    function testforcedWithdrawal() public {
        vm.startPrank(initialOwner);
        vm.deal(initialOwner, 1 ether);
        gateway.forcedWithdrawalETH(initialOwner, 100000, 10, new bytes(0));
        assertEq(messageQueue.messageIndex(), 1);
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

     function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
