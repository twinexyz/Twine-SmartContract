// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Types} from "../libraries/rlp/Types.sol";
import {TwineChain} from "../L1/rollup/TwineChain.sol";
import {ITwineChain} from "../L1/rollup/ITwineChain.sol";
import {L1MessageQueue} from "../L1/rollup/L1MessageQueue.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
import {IL1MessageQueue} from "../L1/rollup/IL1MessageQueue.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";

import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";

import {IL1ETHGateway, L1ETHGateway} from "../L1/gateways/L1ETHGateway.sol";
import {IL2ETHGateway, L2ETHGateway} from "../L2/gateways/L2ETHGateway.sol";
import {IL1GatewayRouter, L1GatewayRouter} from "../L1/gateways/L1GatewayRouter.sol";
import {IL2ERC20Gateway, L2CustomERC20Gateway} from "../L2/gateways/L2CustomERC20Gateway.sol";

contract TwineChainTest is Test {
    RoleManager roleManager;
    TwineChain public twineChain;
    L1MessageQueue public messageQueue;
    L1TwineMessenger public l1TwineMessenger;
    L2TwineMessenger private l2Messenger;
    L2ETHGateway private counterpartGateway;
    L1ETHGateway private gateway;
    L1GatewayRouter private router;

    address public verifier;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_OPERATIONS_HANDLER =
        keccak256("TWINE_OPERATIONS_HANDLER");
    bytes32 public constant TWINE_GATEWAYS = keccak256("TWINE_GATEWAYS");
    bytes32 public constant TWINE_CHAIN = keccak256("TWINE_CHAIN");

    function setUp() public {
        vm.startPrank(initialOwner);
        deal(initialOwner, 20 ether);

        verifier = address(new SP1Verifier());

        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );
        roleManager = RoleManager(roleManagerAddress);
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.grantRole(TWINE_OPERATIONS_HANDLER, initialOwner);

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

        // setup L1MessageQueue
        address L1MessageQueueAddress = Upgrades.deployTransparentProxy(
            "L1MessageQueue.sol",
            msg.sender,
            abi.encodeCall(
                L1MessageQueue.initialize,
                (0, address(0), address(roleManager))
            )
        );

        messageQueue = L1MessageQueue(L1MessageQueueAddress);

        // setup L2TwineMessenger
        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (0, address(0), address(0))
            )
        );

        l2Messenger = L2TwineMessenger(L2TwineMessengerAddress);

        // setup TwineChain
        address TwineChainAddress = Upgrades.deployTransparentProxy(
            "TwineChain.sol",
            msg.sender,
            abi.encodeCall(
                TwineChain.initialize,
                (address(messageQueue), verifier, address(roleManager))
            )
        );

        twineChain = TwineChain(TwineChainAddress);

        // Deploying an upgradeable proxy for L1TwineMessenger
        address L1TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L1TwineMessenger.sol",
            initialOwner,
            abi.encodeCall(
                L1TwineMessenger.initialize,
                (
                    address(0),
                    address(messageQueue),
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
        gateway = L1ETHGateway(L1ETHGatewayAddress);

        //setup gateway in router;
        vm.startPrank(initialOwner);
        router.setETHGateway(address(gateway));
        router.setDefaultERC20Gateway(address(gateway));
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.checkRole(CHAIN_ADMIN, initialOwner);
        gateway.setRoleManagerAddress(address(roleManager));
        // l1TwineMessenger.setGatewayAddress(address(gateway), address(0));

        // SetUp Message Qeueue
        messageQueue.setMessengerAddress(address(l1TwineMessenger));
        messageQueue.setChainId(1700);
        messageQueue.setRoleManager(address(roleManager));

        // SetUp Twine Chain
        twineChain.setChainId(1700);
        twineChain.setRoleManagerAddress(address(roleManager));
        twineChain.setMessengerQueueAddress(address(messageQueue));
        twineChain.setGatewayAddress(address(gateway), address(gateway));

        // SetUp Messenger
        l1TwineMessenger.setMessengerQueueAddress(address(messageQueue));
        l1TwineMessenger.setRollupAddress(address(twineChain));

        roleManager.grantRole(TWINE_GATEWAYS, address(gateway));
        roleManager.grantRole(TWINE_CHAIN, address(twineChain));
        vm.stopPrank();
    }

    function testTheWholeFlow() public {
        /******************
         * Depositing ETH *
         *****************/
        // assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 0);
        // assertEq(address(gateway).balance, 0 ether);

        vm.startPrank(initialOwner);
        // uint256 depositAmount = 5 ether;
        // gateway.depositETH{value: depositAmount}(
        //     initialOwner,
        //     depositAmount,
        //     0
        // );

        // assertEq(address(gateway).balance, 5 ether);
        // assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 1);

        // console.log("ETH DEPOSIT MESSAGE");
        // L1MessageQueue.MessageData memory deposit = messageQueue
        //     .getCrossDomainDepositMessage(0);
        // console.log("nonce", deposit.nonce);
        // console.log("chainId", deposit.chainId);
        // console.log("blockNumber", deposit.blockNumber);
        // console.log("fromAddress", deposit.fromAddress);
        // console.log("toAddress", deposit.toAddress);
        // console.log("l1Token", deposit.l1Token);
        // console.log("l2Token", deposit.l2Token);
        // console.log("amount", deposit.amount);

        // /**************************
        //  * Force Withdrawaing ETH *
        //  *************************/
        // assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 0);

        // vm.startPrank(initialOwner);
        // uint256 withdrawAmount = 1 ether;
        // gateway.forcedWithdrawalETH(
        //     initialOwner,
        //     withdrawAmount,
        //     0,
        //     new bytes(0)
        // );

        // assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 1);

        // console.log("ETH DEPOSIT MESSAGE");
        // L1MessageQueue.MessageData memory withdraw = messageQueue
        //     .getCrossDomainWithdrawalMessage(0);
        // console.log("nonce", withdraw.nonce);
        // console.log("chainId", withdraw.chainId);
        // console.log("blockNumber", withdraw.blockNumber);
        // console.log("fromAddress", withdraw.fromAddress);
        // console.log("toAddress", withdraw.toAddress);
        // console.log("l1Token", withdraw.l1Token);
        // console.log("l2Token", withdraw.l2Token);
        // console.log("amount", withdraw.amount);

        // /*******************
        //  * Preparing Input *
        //  ******************/

        // bytes32 receiptRoot1 = 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23;
        // bytes32 receiptRoot2 = 0x30ef9aeb96f07ce8c486b0f932edb1ab5840b1e611930b7a451d3f839dc77980;
        // bytes32 receiptRoot3 = 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5;

        // bytes32 transactionRoot = 0x9bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a6854617;

        // ITwineChain.CommitBlockInfo memory blockOne = ITwineChain
        //     .CommitBlockInfo({
        //         blockNumber: 1,
        //         blockHash: transactionRoot,
        //         transactionRoot: transactionRoot,
        //         receiptRoot: receiptRoot1
        //     });

        // ITwineChain.CommitBlockInfo memory blockTwo = ITwineChain
        //     .CommitBlockInfo({
        //         blockNumber: 2,
        //         blockHash: transactionRoot,
        //         transactionRoot: transactionRoot,
        //         receiptRoot: receiptRoot2
        //     });

        // ITwineChain.CommitBlockInfo memory blockThree = ITwineChain
        //     .CommitBlockInfo({
        //         blockNumber: 3,
        //         blockHash: transactionRoot,
        //         transactionRoot: transactionRoot,
        //         receiptRoot: receiptRoot3
        //     });

        // ITwineChain.CommitBlockInfo[]
        //     memory commitBlockInfos = new ITwineChain.CommitBlockInfo[](3);
        // commitBlockInfos[0] = blockOne;
        // commitBlockInfos[1] = blockTwo;
        // commitBlockInfos[2] = blockThree;
        // bytes32 genesisBlockHash = bytes32(0);
        // twineChain.commitGenesisBlock(genesisBlockHash);

        // twineChain.commitBatch(1, 3, commitBlockInfos);
        // assertEq(twineChain.lastCommittedBlockNumber(), 3);

        // bytes
        //     memory publicInputForExecution = hex"00000000000000010000000000000003b26d8e64ccd5efc0952a3b2da3c8402bd9ff15e8a724e190d6b3cd05b1a130b0";
        // bytes
        //     memory executionProof = hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448";

        // twineChain.finalizeBatch(publicInputForExecution, executionProof);
        // assertEq(twineChain.lastFinalizedBlockNumber(), 3);

        // bytes
        //     memory transactionInfo = hex"0000000000000001000000000000000363f95c640179b6fa94325f0216981bc7761ed46c0d35fdb0b615382d99b9af9100000000000000015a0bd12eaeef0baa2fedefb040779521e0910764396fec6c0073d0cacc708a4300000000000000014027478e26eb1732d808619f0c8907b2d095b30372c0e6bda02c804a8ffe22660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015a0bd12eaeef0baa2fedefb040779521e0910764396fec6c0073d0cacc708a4300000000000000014027478e26eb1732d808619f0c8907b2d095b30372c0e6bda02c804a8ffe226600000000000000000000000000000000000000000000000000000000000000000000000000000000";
        // twineChain.commitAndFinalizeTransactions(
        //     transactionInfo,
        //     executionProof
        // );

        // assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 0);
        // assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 0);
        // assertEq(messageQueue.nextCrossDomainExecutionMessageIndex(), 1);

        bytes
            memory verficationProof = hex"000f22880a7a1236d352a30e6e08041cccb5a88ebc862c2bbaf0d337237dbaf92a56f369d49153a76df06d7d6fb06f3209e1181bda8cdaa316c6600052a0a4b726bb1a2dd4e2ded55ad315cdcb795a8416781b2bb91b68932beebc118c0ac8491eec5e994fbb7472c13cd04eee69d12178a266fdcd1dd150b0d435752fde4ef92f9431039ef5cf3be8711d3122f6f123c4fb2d2e2565d91507351a3aa34cce792bd05d96d44dc828302f6f5630c423823acff2958b1e8fd9d64faec006076ada0185646aea248dda7e3966d21eff0a674b112a1af7a8ba27f2adb2c59d72c562277242d1923c6ff47e8c938c3895ae98f0a7c5180f2b73db9d38c4bb6c76a60a";
        bytes32 sp1VKey = hex"001329f041628d28f69f201b7a61845cf76af1fce9b1be3e434d5adc34fe70fc";
        bytes
            memory publicInput = hex"00000000000001e000000000000001e1c55bc7420ea1a7a5b8981e0eb1591b9c7ea3c12127e8f3b8faf5243ad619fb23";
        bytes memory finalProof = twineChain.prependBytes(verficationProof);
        SP1Verifier(verifier).verifyProof(sp1VKey, publicInput, finalProof);
        console.log("verification success");
    }
}
