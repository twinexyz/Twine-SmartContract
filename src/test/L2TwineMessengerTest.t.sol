// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {IMockAave, MockAave} from "./mocks/MockAave.sol";
import {L2MsgExecutor} from "../L2/L2MsgExecutor.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
import {TwineStandardERC20} from "../libraries/token/TwineStandardERC20.sol";
import {IL2TwineMessenger, L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {IL2ERC20Gateway, L2CustomERC20Gateway} from "../L2/gateways/L2CustomERC20Gateway.sol";
import {IMockTwineSystemStorage, MockTwineSystemStorage} from "./mocks/MockTwineSystemStorage.sol";
contract L2TwineMessengerTest is Test {
    address l1Token;
    address l2Token;
    MockAave aave;
    MockTwineSystemStorage twineStorage;
    L2CustomERC20Gateway private gateway;
    L2TwineMessenger private messenger;
    RoleManager private roleManager;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_OPERATIONS_HANDLER =
        keccak256("TWINE_OPERATIONS_HANDLER");
    bytes32 public constant TWINE_MESSENGER = keccak256("TWINE_MESSENGER");

    function setUp() public {
        vm.startPrank(initialOwner);
        twineStorage = new MockTwineSystemStorage();
        aave = new MockAave();
        // Setup RoleManager
        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );
        roleManager = RoleManager(roleManagerAddress);
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.grantRole(TWINE_OPERATIONS_HANDLER, initialOwner);
        roleManager.grantRole(TWINE_MESSENGER, initialOwner);

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
                (
                    0,
                    address(0),
                    address(roleManager),
                    L2MessageExecutorAddress,
                    address(twineStorage)
                )
            )
        );
        messenger = L2TwineMessenger(L2TwineMessengerAddress);
        roleManager.grantRole(TWINE_MESSENGER, address(messenger));

        address L2CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L2CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L2CustomERC20Gateway.initialize,
                (address(0), address(messenger), address(roleManager))
            )
        );
        gateway = L2CustomERC20Gateway(L2CustomERC20GatewayAddress);
        l1Token = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            msg.sender,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("MockERC20", "ME", 18, address(gateway))
            )
        );
        l2Token = Upgrades.deployTransparentProxy(
            "TwineStandardERC20.sol",
            msg.sender,
            abi.encodeCall(
                TwineStandardERC20.initialize,
                ("L2MockERC20", "LME", 18, address(gateway))
            )
        );
        gateway.updateTokenMapping(0, l2Token, addressToString(l1Token));
        twineStorage.setInitialTwineMessenger(address(messenger));
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

    function testHandleDepositsWithdrawDepositOnly() public {
        vm.startPrank(initialOwner);
        messenger.setTokenGateWay(0, l2Token, address(gateway));
         IL2TwineMessenger.L1ForcedTxn[] memory emptyForcedTxns = new IL2TwineMessenger.L1ForcedTxn[](0);
        L2TwineMessenger.L1Txns memory l1Txns = IL2TwineMessenger.L1Txns({
            nonce: 1,
            tokenTxn: IL2TwineMessenger.TokenTxn({
                chainId: 0,
                amount: 5,
                token: l2Token,
                receiver: initialOwner,
                deposit: true
            }),
            l1ForcedTxn: emptyForcedTxns
        });
        vm.mockCall(
            address(0x15), 
            abi.encode("deposit input"),
            abi.encode(l1Txns)
        );
        messenger.handleDepoistsWithdraws(
            abi.encode("deposit input")
        );
        assertEq(
            twineStorage.l1MessageExecutedCount(
                0,
                IMockTwineSystemStorage.L1TxnType.Deposit
            ),
            1
        );

        assertEq(aave.totalDeposits(), 0);
        vm.stopPrank();
    }
      function testHandleDepositsWithdrawDepositWithMessage() public {
        vm.startPrank(initialOwner);
        messenger.setTokenGateWay(0, l2Token, address(gateway));
        IL2TwineMessenger.L1ForcedTxn[]
            memory forcedTxns = new IL2TwineMessenger.L1ForcedTxn[](1);
        bytes
            memory depositCalldata = hex"e8eda9df00000000000000000000000062323ec6c891daa8e432a6578c9c0b4c0db0356b000000000000000000000000000000000000000000000000000000000000000100000000000000000000000019b78ff82c94b5e517f2279f3fbf10498b0391790000000000000000000000000000000000000000000000000000000000000000";
        forcedTxns[0] = IL2TwineMessenger.L1ForcedTxn({
            targetContract: address(aave),
            value: 0,
            data: depositCalldata
        });
        L2TwineMessenger.L1Txns memory l1Txns = IL2TwineMessenger.L1Txns({
            nonce: 1,
            tokenTxn: IL2TwineMessenger.TokenTxn({
                chainId: 0,
                amount: 5,
                token: l2Token,
                receiver: initialOwner,
                deposit: true
            }),
            l1ForcedTxn: forcedTxns
        });
        vm.mockCall(
            address(0x15), 
            abi.encode("deposit input"),
            abi.encode(l1Txns)
        );
        messenger.handleDepoistsWithdraws(
            abi.encode("deposit input")
        );
        assertEq(
            twineStorage.l1MessageExecutedCount(
                0,
                IMockTwineSystemStorage.L1TxnType.Deposit
            ),
            1
        );

        assertEq(aave.totalDeposits(), 1);
        vm.stopPrank();
    }
    function testHandleDepositsWithdrawWithdrawOnly() public {
        vm.startPrank(initialOwner);
        messenger.setTokenGateWay(0, l2Token, address(gateway));
        IL2TwineMessenger.L1ForcedTxn[] memory emptyForcedTxns = new IL2TwineMessenger.L1ForcedTxn[](0);
        L2TwineMessenger.L1Txns memory l1Txns = IL2TwineMessenger.L1Txns({
            nonce: 1,
            tokenTxn: IL2TwineMessenger.TokenTxn({
                chainId: 0,
                amount: 5,
                token: l2Token,
                receiver: initialOwner,
                deposit: true
            }),
            l1ForcedTxn: emptyForcedTxns
        });
        vm.mockCall(
            address(0x15), 
            abi.encode("deposit input"),
            abi.encode(l1Txns)
        );
        messenger.handleDepoistsWithdraws(
            abi.encode("deposit input")
        );

        assertEq(
            twineStorage.l1MessageExecutedCount(
                0,
                IMockTwineSystemStorage.L1TxnType.Deposit
            ),
            1
        );
        L2TwineMessenger.L1Txns memory l1WithdrawTxns = IL2TwineMessenger.L1Txns({
            nonce: 1,
            tokenTxn: IL2TwineMessenger.TokenTxn({
                chainId: 0,
                amount: 2,
                token: l2Token,
                receiver: initialOwner,
                deposit: false
            }),
            l1ForcedTxn: emptyForcedTxns
        });
        vm.mockCall(
            address(0x15), 
            abi.encode("withdraw input"),
            abi.encode(l1WithdrawTxns)
        );
        messenger.handleDepoistsWithdraws(
            abi.encode("withdraw input")
        );

        assertEq(
            twineStorage.l1MessageExecutedCount(
                0,
                IMockTwineSystemStorage.L1TxnType.Deposit
            ),
            1
        );
        assertEq(
            twineStorage.l1MessageExecutedCount(
                0,
                IMockTwineSystemStorage.L1TxnType.ForcedWithdraw
            ),
            1
        );
        assertEq(aave.totalDeposits(), 0);
        vm.stopPrank();
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
