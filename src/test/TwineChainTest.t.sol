// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";

import {TwineChain} from "../L1/rollup/TwineChain.sol";
import {ITwineChain} from "../L1/rollup/ITwineChain.sol";
import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";
import {L1MessageHandler} from "../L1/rollup/L1MessageHandler.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
import {IL1MessageHandler} from "../L1/rollup/IL1MessageHandler.sol";
import {IL1ETHGateway, L1ETHGateway} from "../L1/gateways/L1ETHGateway.sol";
import {IL2ETHGateway, L2ETHGateway} from "../L2/gateways/L2ETHGateway.sol";  
import {IL1GatewayRouter, L1GatewayRouter} from "../L1/gateways/L1GatewayRouter.sol";
import {IL1ERC20Gateway, L1CustomERC20Gateway} from "../L1/gateways/L1CustomERC20Gateway.sol";

contract TwineChainTest is Test {
    error ErrorZeroAddress();
    RoleManager roleManager;
    TwineChain public twineChain;
    L1ETHGateway private ethGateway;
    L1GatewayRouter private router;
    L1MessageHandler public messageHandler;
    L1CustomERC20Gateway private erc20Gateway;
    L1TwineMessenger public l1TwineMessenger;

    address public verifier;
    address public newMessageHandler;
    address public newVerifierAddress;
    address admin = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_OPERATIONS_HANDLER =
        keccak256("TWINE_OPERATIONS_HANDLER");
    bytes32 public constant TWINE_GATEWAYS = keccak256("TWINE_GATEWAYS");
    bytes32 public constant TWINE_CHAIN = keccak256("TWINE_CHAIN");
    bytes32 finalizeVKey;
    bytes32 refundVKey;
    bytes32 forcedWithdrawalVKey;
    bytes32 l2WithdrawalVkey;

    function setUp() public {
        vm.startPrank(admin);
        newMessageHandler = makeAddr("newMessageHandler");
        newVerifierAddress = makeAddr("newVerifierAddress");
        finalizeVKey = keccak256("finalizeVKey");
        refundVKey = keccak256("refundVKey");
        forcedWithdrawalVKey = keccak256("forcedWithdrawalVKey");
        l2WithdrawalVkey = keccak256("l2WithdrawalVkey");

        deal(admin, 20 ether);

        verifier = address(new SP1Verifier());

        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (admin))
        );
        roleManager = RoleManager(roleManagerAddress);
        roleManager.grantRole(CHAIN_ADMIN, admin);
        roleManager.grantRole(TWINE_OPERATIONS_HANDLER, admin);

        // setup GatewayRouter
        address L1GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L1GatewayRouter.sol",
            msg.sender,
            abi.encodeCall(
                L1GatewayRouter.initialize,
                (address(0), address(0), address(roleManager))
            )
        );
        router = L1GatewayRouter(L1GatewayRouterAddress);

        // setup L1MessageHandler
        address L1MessageHandlerAddress = Upgrades.deployTransparentProxy(
            "L1MessageHandler.sol",
            msg.sender,
            abi.encodeCall(
                L1MessageHandler.initialize,
                (0, address(0), address(roleManager))
            )
        );

        messageHandler = L1MessageHandler(L1MessageHandlerAddress);

        // setup TwineChain
        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            msg.sender,
            abi.encodeCall(
                TwineChain.initialize,
                (address(messageHandler), verifier, address(roleManager))
            )
        );

        twineChain = TwineChain(TwineChainAddress);

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            admin,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (
                    address(0),
                    address(messageHandler),
                    TwineChainAddress,
                    roleManagerAddress
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
        ethGateway = L1ETHGateway(L1ETHGatewayAddress);
        ethGateway.setL2TokenAddress(0x19B78FF82C94b5E517f2279f3fBF10498B039179);
        address L1CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L1CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L1CustomERC20Gateway.initialize,
                (
                    address(router),
                    address(l1TwineMessenger),
                    address(roleManager),
                    1700
                )
            )
        );

        erc20Gateway = L1CustomERC20Gateway(L1CustomERC20GatewayAddress);

        //setup ethGateway in router;
        vm.startPrank(admin);
        router.setETHGateway(address(ethGateway));
        router.setDefaultERC20Gateway(address(ethGateway));
        roleManager.grantRole(CHAIN_ADMIN, admin);
        roleManager.checkRole(CHAIN_ADMIN, admin);
        ethGateway.setRoleManagerAddress(address(roleManager));

        // SetUp Message Qeueue
        messageHandler.setMessengerAddress(address(l1TwineMessenger));
        messageHandler.setChainId(1700);
        messageHandler.setRoleManager(address(roleManager));

        // SetUp Twine Chain
        twineChain.setChainId(1700);
        twineChain.setRoleManagerAddress(address(roleManager));
        twineChain.setMessageHandlerAddress(address(messageHandler));
        twineChain.setGatewayAddress(address(ethGateway), address(ethGateway));

        // SetUp Messenger
        l1TwineMessenger.setMessageHandlerAddress(address(messageHandler));
        l1TwineMessenger.setRollupAddress(address(twineChain));

        roleManager.grantRole(TWINE_GATEWAYS, address(ethGateway));
        roleManager.grantRole(TWINE_CHAIN, address(twineChain));
        vm.stopPrank();
    }

    function testSetChainId() public {
        assertEq(twineChain.chainId(), 1700);
        vm.startPrank(admin);
        twineChain.setChainId(18000);
        vm.stopPrank();
        assertEq(twineChain.chainId(), 18000);
    }

    function testSetRoleManagerNonAdminReverts() public {
        address nonAdminUser = address(0x123);
        address newRoleManager = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        twineChain.setRoleManagerAddress(newRoleManager);
        
    }

    function testSetRoleManagerZeroAddressNotAllowed() public {
        vm.startPrank(admin);
        vm.expectRevert(ErrorZeroAddress.selector);
        twineChain.setRoleManagerAddress(address(0));
        vm.stopPrank();
    }

    function testSetRoleManager() public {
        address newRoleManager = address(0x123);
        vm.startPrank(admin);
        twineChain.setRoleManagerAddress(newRoleManager);
        vm.stopPrank();
        assertEq(twineChain.roleManager(), newRoleManager);
    }

    function testSetMessengerQueueAddressNonAdminReverts() public {
        address nonAdminUser = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        twineChain.setMessageHandlerAddress(newMessageHandler);
        vm.stopPrank();
    }

    function testSetMessengerQueueZeroAddressNotAllowed() public {
        vm.startPrank(admin);
        vm.expectRevert(ErrorZeroAddress.selector);
        twineChain.setMessageHandlerAddress(address(0));
        vm.stopPrank();
    }

    function testSetMesseHandlerAddress() public {
        vm.prank(admin);
        twineChain.setMessageHandlerAddress(newMessageHandler);
        assertEq(twineChain.messageHandler(), newMessageHandler);
    }

    function testSetVeriferAddressNonAdminReverts() public {
        address nonAdminUser = address(0x123);
        address newRoleManager = address(0x123);
        vm.startPrank(nonAdminUser);
        vm.expectRevert();
        twineChain.setVeriferAddress(newRoleManager);
        vm.stopPrank();
    }

    function testsetVeriferAddressZeroAddressNotAllowed() public {
        vm.startPrank(admin);
        vm.expectRevert(ErrorZeroAddress.selector);
        twineChain.setVeriferAddress(address(0));
        vm.stopPrank();
    }

    function testSetVeriferAddressAddress() public {
        vm.prank(admin);
        twineChain.setVeriferAddress(newVerifierAddress);
        assertEq(twineChain.verifier(), newVerifierAddress);
    }

    function testSetProgramVKeyRevertsForNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.prank(nonAdminUser);
        vm.expectRevert();
        twineChain.setProgramVKey(finalizeVKey, refundVKey, forcedWithdrawalVKey, l2WithdrawalVkey);
    }

    function testSetProgramVKeyZeroBytesNotAllowed() public {
        vm.prank(admin);
        vm.expectRevert();
        twineChain.setProgramVKey(bytes32(0), bytes32(0), bytes32(0), bytes32(0));
    }

    function testSetProgramVKey() public {
        vm.prank(admin);
        twineChain.setProgramVKey(finalizeVKey, refundVKey, forcedWithdrawalVKey, l2WithdrawalVkey);
        assertEq(twineChain.finalizeVKey(), finalizeVKey);
        assertEq(twineChain.refundVKey(), refundVKey);
        assertEq(twineChain.forcedWithdrawalVKey(), forcedWithdrawalVKey);
        assertEq(twineChain.l2WithdrawalVkey(), l2WithdrawalVkey);
    }

    function testsetGatewayAddressForNonAdmin() public {
        address nonAdminUser = address(0x123);
        vm.prank(nonAdminUser);
        vm.expectRevert();
        twineChain.setProgramVKey(finalizeVKey, refundVKey, forcedWithdrawalVKey, l2WithdrawalVkey);
    }

    function testsetGatewayAddressZeroNotAllowed() public {
        vm.prank(admin);
        vm.expectRevert();
        twineChain.setGatewayAddress(address(0), address(0));
    }

    function testsetGatewayAddress() public {
        vm.prank(admin);
        console.log(address(ethGateway), address(erc20Gateway));
        twineChain.setGatewayAddress(
            address(ethGateway),
            address(erc20Gateway)
        );

        assertEq(twineChain.ethGateway(), address(ethGateway));
        assertEq(twineChain.ERC20Gateway(), address(erc20Gateway));
    }

    function testcommitGenesisBlock() public {
        vm.prank(admin);
        bytes32 genesisBatch = keccak256("genesiBatch");
        twineChain.commitGenesisBlock(genesisBatch);
        assert(twineChain.isGenesisBlockCommitted() == true);
    }

    function testCommitAndFinalizeBatch() public {
        uint64 batchNumber = 1;
        uint64 totalEthMsgHandledOnTwine = 3;
        uint64 totalSolanaMsgHandledOnTwine = 2;
        bytes32 batchHash =  0x8a58ec38439a3ccc22aaf10ee418aca264cd1bc16c5bab8f0378e9697210e8b5;
        bytes32 genesisBlockHash = bytes32(0);
        vm.startPrank(admin);
        twineChain.commitGenesisBlock(genesisBlockHash);

        bytes memory publicValues = abi.encodePacked(
            genesisBlockHash,
            batchHash,
            totalEthMsgHandledOnTwine,
            totalSolanaMsgHandledOnTwine
        );

        twineChain.commitAndFinalizeBatch(batchNumber,publicValues, publicValues);
        assertEq(twineChain.lastCommittedBatchNumber(), 1);
        assertEq(twineChain.lastFinalizedBatchNumber(), 1);
        vm.stopPrank();
    }

//     function testTheWholeFlow() public {
//         /******************
//          * Depositing ETH *
//          *****************/
//         assertEq(messageHandler.nextCrossDomainDepositMessageIndex(), 0);
//         assertEq(address(ethGateway).balance, 0 ether);

//         vm.startPrank(admin);
//         uint256 depositAmount = 5 ether;
//         ethGateway.depositETH{value: depositAmount}(
//             admin,
//             depositAmount,
//             0
//         );

//         assertEq(address(ethGateway).balance, 5 ether);
//         assertEq(messageHandler.nextCrossDomainDepositMessageIndex(), 1);

//         console.log("ETH DEPOSIT MESSAGE");
//         L1MessageHandler.MessageData memory deposit = messageHandler
//             .getCrossDomainDepositMessage(0);
//         console.log("nonce", deposit.nonce);
//         console.log("chainId", deposit.chainId);
//         console.log("blockNumber", deposit.blockNumber);
//         console.log("fromAddress", deposit.fromAddress);
//         console.log("toAddress", deposit.toAddress);
//         console.log("l1Token", deposit.l1Token);
//         console.log("l2Token", deposit.l2Token);
//         console.log("amount", deposit.amount);
//         console.logBytes(deposit.message);

//         /**************************
//          * Force Withdrawaing ETH *
//          *************************/
//         assertEq(messageHandler.nextCrossDomainWithdrawalMessageIndex(), 0);

//         vm.startPrank(admin);
//         uint256 withdrawAmount = 1 ether;
//         ethGateway.forcedWithdrawalETH(
//             admin,
//             withdrawAmount,
//             0,
//             new bytes(0)
//         );

//         assertEq(messageHandler.nextCrossDomainWithdrawalMessageIndex(), 1);

//         console.log("ETH WITHDRAW MESSAGE");
//         L1MessageHandler.MessageData memory withdraw = messageHandler
//             .getCrossDomainWithdrawalMessage(0);
//         console.log("nonce", withdraw.nonce);
//         console.log("chainId", withdraw.chainId);
//         console.log("blockNumber", withdraw.blockNumber);
//         console.log("fromAddress", withdraw.fromAddress);
//         console.log("toAddress", withdraw.toAddress);
//         console.log("l1Token", withdraw.l1Token);
//         console.log("l2Token", withdraw.l2Token);
//         console.log("amount", withdraw.amount);
//         console.logBytes(withdraw.message);

//         /*******************
//          * Preparing Input *
//          ******************/

//         bytes32 receiptRoot1 = 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23;
//         bytes32 receiptRoot2 = 0x30ef9aeb96f07ce8c486b0f932edb1ab5840b1e611930b7a451d3f839dc77980;
//         bytes32 receiptRoot3 = 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5;

//         bytes32 transactionRoot = 0x9bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a6854617;

//         ITwineChain.CommitBlockInfo memory blockOne = ITwineChain
//             .CommitBlockInfo({
//                 blockNumber: 1,
//                 blockHash: transactionRoot,
//                 transactionRoot: transactionRoot,
//                 receiptRoot: receiptRoot1
//             });

//         ITwineChain.CommitBlockInfo memory blockTwo = ITwineChain
//             .CommitBlockInfo({
//                 blockNumber: 2,
//                 blockHash: transactionRoot,
//                 transactionRoot: transactionRoot,
//                 receiptRoot: receiptRoot2
//             });

//         ITwineChain.CommitBlockInfo memory blockThree = ITwineChain
//             .CommitBlockInfo({
//                 blockNumber: 3,
//                 blockHash: transactionRoot,
//                 transactionRoot: transactionRoot,
//                 receiptRoot: receiptRoot3
//             });

//         ITwineChain.CommitBlockInfo[]
//             memory commitBlockInfos = new ITwineChain.CommitBlockInfo[](3);
//         commitBlockInfos[0] = blockOne;
//         commitBlockInfos[1] = blockTwo;
//         commitBlockInfos[2] = blockThree;
//         bytes32 genesisBlockHash = bytes32(0);
//         twineChain.commitGenesisBlock(genesisBlockHash);

//         twineChain.commitBatch(1, 3, commitBlockInfos);
//         assertEq(twineChain.lastCommittedBlockNumber(), 3);

//         bytes
//             memory publicInputForExecution = hex"00000000000000010000000000000003b26d8e64ccd5efc0952a3b2da3c8402bd9ff15e8a724e190d6b3cd05b1a130b0";
//         bytes
//             memory executionProof = hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448";

//         twineChain.finalizeBatch(publicInputForExecution, executionProof);
//         assertEq(twineChain.lastFinalizedBlockNumber(), 3);

//         bytes
//             memory transactionInfo = hex"0000000000000001000000000000000363f95c640179b6fa94325f0216981bc7761ed46c0d35fdb0b615382d99b9af9100000000000000013bfe2a0287b9929daac167b8569cf2ee58c44c92774fdabeebca9d2a58075a04000000000000000165f6575f66b2ce40e6db8722fa6695875ae93132ce662cd0cf16e2dea0cb59eb0000000000000000c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a47000000000000000013bfe2a0287b9929daac167b8569cf2ee58c44c92774fdabeebca9d2a58075a04000000000000000165f6575f66b2ce40e6db8722fa6695875ae93132ce662cd0cf16e2dea0cb59eb0000000000000000c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
//         twineChain.commitAndFinalizeTransactions(
//             transactionInfo,
//             executionProof
//         );

//         assertEq(messageHandler.nextCrossDomainDepositMessageIndex(), 0);
//         assertEq(messageHandler.nextCrossDomainWithdrawalMessageIndex(), 0);
//         assertEq(messageHandler.nextCrossDomainExecutionMessageIndex(), 1);
//     }

//     function testTheSplTokenWithdrawalFinalization() public {
//        /******************
//          * Depositing ETH *
//          *****************/
//         assertEq(messageHandler.nextCrossDomainDepositMessageIndex(), 0);
//         assertEq(address(ethGateway).balance, 0 ether);

//         vm.startPrank(admin);
//         uint256 depositAmount = 5 ether;
//         ethGateway.depositETH{value: depositAmount}(
//             admin,
//             depositAmount,
//             0
//         );

//         assertEq(address(ethGateway).balance, 5 ether);
//         assertEq(messageHandler.nextCrossDomainDepositMessageIndex(), 1);

//         console.log("ETH DEPOSIT MESSAGE");
//         L1MessageHandler.MessageData memory deposit = messageHandler
//             .getCrossDomainDepositMessage(0);
//         console.log("nonce", deposit.nonce);
//         console.log("chainId", deposit.chainId);
//         console.log("blockNumber", deposit.blockNumber);
//         console.log("fromAddress", deposit.fromAddress);
//         console.log("toAddress", deposit.toAddress);
//         console.log("l1Token", deposit.l1Token);
//         console.log("l2Token", deposit.l2Token);
//         console.log("amount", deposit.amount);

//         /**************************
//          * Force Withdrawaing ETH *
//          *************************/
//         assertEq(messageHandler.nextCrossDomainWithdrawalMessageIndex(), 0);

//         vm.startPrank(admin);
//         uint256 withdrawAmount = 1 ether;
//         ethGateway.forcedWithdrawalETH(
//             admin,
//             withdrawAmount,
//             0,
//             new bytes(0)
//         );

//         assertEq(messageHandler.nextCrossDomainWithdrawalMessageIndex(), 1);

//         console.log("ETH WITHDRAW MESSAGE");
//         L1MessageHandler.MessageData memory withdraw = messageHandler
//             .getCrossDomainWithdrawalMessage(0);
//         console.log("nonce", withdraw.nonce);
//         console.log("chainId", withdraw.chainId);
//         console.log("blockNumber", withdraw.blockNumber);
//         console.log("fromAddress", withdraw.fromAddress);
//         console.log("toAddress", withdraw.toAddress);
//         console.log("l1Token", withdraw.l1Token);
//         console.log("l2Token", withdraw.l2Token);
//         console.log("amount", withdraw.amount);

//         /*******************
//          * Preparing Input *
//          ******************/

//         bytes32 receiptRoot1 = 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23;
//         bytes32 receiptRoot2 = 0x30ef9aeb96f07ce8c486b0f932edb1ab5840b1e611930b7a451d3f839dc77980;
//         bytes32 receiptRoot3 = 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5;

//         bytes32 transactionRoot = 0x9bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a6854617;

//         ITwineChain.CommitBlockInfo memory blockOne = ITwineChain
//             .CommitBlockInfo({
//                 blockNumber: 1,
//                 blockHash: transactionRoot,
//                 transactionRoot: transactionRoot,
//                 receiptRoot: receiptRoot1
//             });

//         ITwineChain.CommitBlockInfo memory blockTwo = ITwineChain
//             .CommitBlockInfo({
//                 blockNumber: 2,
//                 blockHash: transactionRoot,
//                 transactionRoot: transactionRoot,
//                 receiptRoot: receiptRoot2
//             });

//         ITwineChain.CommitBlockInfo memory blockThree = ITwineChain
//             .CommitBlockInfo({
//                 blockNumber: 3,
//                 blockHash: transactionRoot,
//                 transactionRoot: transactionRoot,
//                 receiptRoot: receiptRoot3
//             });

//         ITwineChain.CommitBlockInfo[]
//             memory commitBlockInfos = new ITwineChain.CommitBlockInfo[](3);
//         commitBlockInfos[0] = blockOne;
//         commitBlockInfos[1] = blockTwo;
//         commitBlockInfos[2] = blockThree;
//         bytes32 genesisBlockHash = bytes32(0);
//         twineChain.commitGenesisBlock(genesisBlockHash);

//         twineChain.commitBatch(1, 3, commitBlockInfos);
//         assertEq(twineChain.lastCommittedBlockNumber(), 3);

//         bytes
//             memory publicInputForExecution = hex"00000000000000010000000000000003b26d8e64ccd5efc0952a3b2da3c8402bd9ff15e8a724e190d6b3cd05b1a130b0";
//         bytes
//             memory executionProof = hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448";

//         twineChain.finalizeBatch(publicInputForExecution, executionProof);
//         assertEq(twineChain.lastFinalizedBlockNumber(), 3);

//         bytes
//             memory transactionInfo = hex"0000000000000001000000000000000363f95c640179b6fa94325f0216981bc7761ed46c0d35fdb0b615382d99b9af9100000000000000013bfe2a0287b9929daac167b8569cf2ee58c44c92774fdabeebca9d2a58075a04000000000000000165f6575f66b2ce40e6db8722fa6695875ae93132ce662cd0cf16e2dea0cb59eb0000000000000000c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a47000000000000000013bfe2a0287b9929daac167b8569cf2ee58c44c92774fdabeebca9d2a58075a04000000000000000165f6575f66b2ce40e6db8722fa6695875ae93132ce662cd0cf16e2dea0cb59eb0000000000000000c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
//         twineChain.commitAndFinalizeTransactions(
//             transactionInfo,
//             executionProof
//         );

//         assertEq(messageHandler.nextCrossDomainDepositMessageIndex(), 0);
//         assertEq(messageHandler.nextCrossDomainWithdrawalMessageIndex(), 0);
//         assertEq(messageHandler.nextCrossDomainExecutionMessageIndex(), 1);
//     }

//     function testfinalizeWithdrawalNativeToken() public {
//         bytes32 receiptRoot3 = 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5;
//         vm.startPrank(admin);
//         bytes
//             memory executionProof = hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448";
//         testTheWholeFlow();
//         ITwineChain.WithdrawalPublicInput
//             memory withdrawalInputOne = ITwineChain.WithdrawalPublicInput({
//                 chainId: 1,
//                 blockNumber: 1,
//                 nonce: 1,
//                 isForcedWithdrawal: 1,
//                 receiptRoot: receiptRoot3,
//                 l1ReceiverAddress: "0x19B78FF82C94b5E517f2279f3fBF10498B039179",
//                 l1TokenAddress: "0x0000000000000000000000000000000000000000",
//                 l2TokenAddress: "0x19B78FF82C94b5E517f2279f3fBF10498B039179",
//                 amount: "1000000000000000000"
//             });
//         ITwineChain.FinalizeWithdrawalInput
//             memory finalizeInputOne = ITwineChain.FinalizeWithdrawalInput({
//                 publicInput: withdrawalInputOne,
//                 inclusionProof: executionProof
//             });
//         twineChain.finalizeWithdrawal(finalizeInputOne);
//         console.log("Gateway balance after:", address(ethGateway).balance);
//         vm.stopPrank();
//     }
}
