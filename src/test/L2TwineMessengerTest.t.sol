// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {L2MsgExecutor} from "../L2/L2MsgExecutor.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
contract L2TwineMessengerTest is Test {
    L2TwineMessenger private messenger;
    RoleManager private roleManager;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_OPERATIONS_HANDLER =
        keccak256("TWINE_OPERATIONS_HANDLER");

    function setUp() public {
        vm.startPrank(initialOwner);
        // Setup RoleManager
        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );
        roleManager = RoleManager(roleManagerAddress);
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.grantRole(TWINE_OPERATIONS_HANDLER, initialOwner);


        address L2MessageExecutorAddress = Upgrades.deployTransparentProxy(
            "L2MsgExecutor.sol",
            initialOwner,
            abi.encodeCall(L2MsgExecutor.initialize, (roleManagerAddress))
        );

        // Setup L2TwineMessenger
        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (0, address(0), address(roleManager),L2MessageExecutorAddress)
            )
        );
        messenger = L2TwineMessenger(L2TwineMessengerAddress);
        vm.stopPrank();
    }

    function testSetRoleManager() public {
        address newRoleManager = address(0x5);
        vm.prank(initialOwner);
        messenger.setRoleManager(newRoleManager);
        assertEq(messenger.roleManager(), newRoleManager);
    }

    function testSetRoleManagerZeroAddress() public {
        vm.prank(initialOwner);
        vm.expectRevert("value cann't be zero");
        messenger.setRoleManager(address(0));
    }

    function testSetFeeVault() public {
        vm.prank(initialOwner);
        messenger.setFeeVault(address(0x5));
        assertEq(messenger.feeVault(), address(0x5));
    }

    function testSetFeeVaultZeroAddress() public {
        vm.prank(initialOwner);
        vm.expectRevert("Address can't be zero");
        messenger.setFeeVault(address(0));
    }

    function testSetCounterpartMessenger() public {
        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 2;
        chainIds[1] = 3;
        address[] memory messengers = new address[](2);
        messengers[0] = address(0x6);
        messengers[1] = address(0x7);

        vm.prank(initialOwner);
        messenger.setCounterpartMessenger(chainIds, messengers);
        vm.stopPrank();

        assertEq(messenger.counterpartMessenger(2), messengers[0]);
        assertEq(messenger.counterpartMessenger(3), messengers[1]);
    }

    function testSetCounterpartMessengerZeroAddress() public {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 2;
        address[] memory messengers = new address[](1);
        messengers[0] = address(0);

        vm.prank(initialOwner);
        vm.expectRevert(" Value cann't be zero");
        messenger.setCounterpartMessenger(chainIds, messengers);
        vm.stopPrank();
    }

    function testSetPrecompileAddress() public {
        vm.startPrank(initialOwner);
        address newConsensusAddress = address(0x123);
        address newBridgingAddress = address(0x456);
        messenger.setPrecompileAddress(newConsensusAddress, newBridgingAddress);
        assertEq(messenger.consensusPrecompileAddress(), newConsensusAddress);
        assertEq(messenger.bridgingPrecompileAddress(), newBridgingAddress);
        vm.stopPrank();
    }

    function testSetPrecompileAddressZeroAddress() public {
        vm.startPrank(initialOwner);
        vm.expectRevert();
        messenger.setPrecompileAddress(address(0), address(0));
        vm.stopPrank();
    }

    function testSetPrecompileAddressNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        messenger.setPrecompileAddress(address(0x123), address(0x456));
        vm.stopPrank();
    }

    function testSetZkVerificationStatus() public {
        vm.startPrank(initialOwner);
        messenger.setZkVerifcationStatus(false);
        assertFalse(messenger.skipVerification());
        messenger.setZkVerifcationStatus(true);
        assertTrue(messenger.skipVerification());
        vm.stopPrank();
    }

    function testSetZkVerificationStatusNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        messenger.setZkVerifcationStatus(false);
        vm.stopPrank();
    }

    function testSetSp1VerifierAddress() public {
        vm.startPrank(initialOwner);
        address newSp1Verifier = address(0x123);
        messenger.setSp1VerifierAddress(newSp1Verifier);
        assertEq(messenger.sp1Verifier(), newSp1Verifier);
        vm.stopPrank();
    }

    function testSetSp1VerifierAddressZeroAddress() public {
        vm.startPrank(initialOwner);
        vm.expectRevert();
        messenger.setSp1VerifierAddress(address(0));
        vm.stopPrank();
    }

    function testSetSp1VerifierAddressNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        messenger.setSp1VerifierAddress(address(0x123));
        vm.stopPrank();
    }

    function testSetVkeys() public {
        vm.startPrank(initialOwner);
        uint256 chainId = 1;
        bytes32 vKey = bytes32(uint256(12345));
        messenger.setVkeys(chainId, vKey);
        assertEq(messenger.vKeys(chainId), vKey);
        vm.stopPrank();
    }

    function testSetVkeysNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        messenger.setVkeys(1, bytes32(uint256(12345)));
        vm.stopPrank();
    }
}
