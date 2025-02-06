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
import {SP1Verifier} from "@sp1-contracts/v3.0.0/SP1VerifierGroth16.sol";

import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";

import {IL1ETHGateway, L1ETHGateway} from "../L1/gateways/L1ETHGateway.sol";
import {IL2ETHGateway, L2ETHGateway} from "../L2/gateways/L2ETHGateway.sol";
import {IL1GatewayRouter, L1GatewayRouter} from "../L1/gateways/L1GatewayRouter.sol";

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
                    address(roleManager)
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
        messageQueue.setMessengerAddress(address(l1TwineMessenger));
        // l1TwineMessenger.setGatewayAddress(address(gateway), address(0));
        vm.stopPrank();
    }

    // function testTheWholeFlow() public {

    //     /******************
    //      * Depositing ETH *
    //      *****************/
    //     assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 0);
    //     assertEq(address(gateway).balance, 0 ether);

    //     vm.startPrank(initialOwner);
    //     uint256 depositAmount = 5 ether;
    //     gateway.depositETH{value: depositAmount}(
    //         initialOwner,
    //         depositAmount,
    //         0
    //     );

    //     assertEq(address(gateway).balance, 5 ether);
    //     assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 1);

    //     /**************************
    //      * Force Withdrawaing ETH *
    //      *************************/
    //     assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 0);

    //     vm.startPrank(initialOwner);
    //     uint256 withdrawAmount = 1 ether;
    //     gateway.forcedWithdrawalETH(
    //         initialOwner,
    //         withdrawAmount,
    //         0,
    //         new bytes(0)
    //     );

    //     assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 1);

    //     /*******************
    //      * Preparing Input *
    //      ******************/

    //     // ITwineChain.StoredBatchInfo memory commit_info = ITwineChain.StoredBatchInfo({
    //     //     batchNumber: 1,
    //     //     batchHash: 0x9bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a6854617,
    //     //     previousStateRoot: 0x30ef9aeb96f07ce8c486b0f932edb1ab5840b1e611930b7a451d3f839dc77980,
    //     //     stateRoot: 0x4ddfbf79e61b76a2b5f3aba12804745074ab12674bef9e141388a86cedd809d1,
    //     //     transactionRoot: 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23,
    //     //     receiptRoot: 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5
    //     // });

    //     bytes memory executionProof = hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448";

    //     /*************************************
    //      * Committing and Finalizing a Batch *
    //      ************************************/

    //     vm.startPrank(initialOwner);
    //     // assertEq(twineChain.lastCommittedBatchNumber(), 0);
    //     // assertEq(twineChain.lastFinalizedBatchNumber(), 0);

    //     // twineChain.commitAndFinalizeBatch(commit_info, executionProof);

    //     // assertEq(twineChain.lastCommittedBatchNumber(), 1);
    //     // assertEq(twineChain.lastFinalizedBatchNumber(), 1);

    //     /****************************************
    //      * Finalizing Transaction for the batch *
    //      ***************************************/
    //     bytes memory transaction_info = hex"0000000000000001ec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b2300000000000000019bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a685461700000000000000019bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a685461700000000000000009bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a6854617";
    //     bytes memory inclusion_proof = hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448";

    //     vm.startPrank(initialOwner);
    //     assertEq(messageQueue.nextCrossDomainExecutionMessageIndex(), 0);
    //     assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 1);
    //     assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 1);

    //     twineChain.commitAndFinalizeTransactions(transaction_info, inclusion_proof);

    //     assertEq(messageQueue.nextCrossDomainExecutionMessageIndex(), 1);
    //     assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 0);
    //     assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 0);

    // }

    function testBatchCommitmentAndFinalization() public {
        // ITwineChain.CommitBatchInfo memory commitBatchInfo = ITwineChain
        //     .CommitBatchInfo({
        //         startBlock: 0,
        //         endBlock: 5,
        //         transactionRoot: 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23,
        //         receiptRoot: 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5
        //     });
        vm.startPrank(initialOwner);
        roleManager.grantRole(TWINE_OPERATIONS_HANDLER, initialOwner);
        uint64 startBlock = 1;
        uint64 endBlock = 3;
        bytes32 blockRootHash = 0x9bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a6854617;
        bytes32 transactionRootOne = 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23;
        bytes32 transactionRootTwo = 0x30ef9aeb96f07ce8c486b0f932edb1ab5840b1e611930b7a451d3f839dc77980;
        bytes32 transactionRootThree = 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5;

        ITwineChain.CommitBlockInfo[]
            memory commitBlockInfos = new ITwineChain.CommitBlockInfo[](3);
        ITwineChain.CommitBlockInfo memory blockOne = ITwineChain
            .CommitBlockInfo({
                blockNumber: 1,
                blockHash: blockRootHash,
                transactionRoot: transactionRootOne,
                receiptRoot: blockRootHash
            });
        ITwineChain.CommitBlockInfo memory blockTwo = ITwineChain
            .CommitBlockInfo({
                blockNumber: 2,
                blockHash: blockRootHash,
                transactionRoot: transactionRootTwo,
                receiptRoot: blockRootHash
            });
        ITwineChain.CommitBlockInfo memory blockThree = ITwineChain
            .CommitBlockInfo({
                blockNumber: 3,
                blockHash: blockRootHash,
                transactionRoot: transactionRootThree,
                receiptRoot: blockRootHash
            });

        commitBlockInfos[0] = blockOne;
        commitBlockInfos[1] = blockTwo;
        commitBlockInfos[2] = blockThree;
        twineChain.commitBatch(startBlock, endBlock, commitBlockInfos);
        // twineChain.FinalizeExecutionBatch(publicInputForExecution, executionProof);

        // messageQueue.testDepositTransaction(1, 0, 0x43ac, 0x19B78FF82C94b5E517f2279f3fBF10498B039179, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, 0x78C71164356ab97D1e7FD26004E4C494f2C4076c, 0x468603D798B4AEA92e7aa06493982F22804eBbEf, 1 ether);
        // messageQueue.testDepositTransaction(2, 0, 0x43c1, 0x19B78FF82C94b5E517f2279f3fBF10498B039179, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, 0x78C71164356ab97D1e7FD26004E4C494f2C4076c, 0x468603D798B4AEA92e7aa06493982F22804eBbEf, 1 ether);
        // messageQueue.testDepositTransaction(3, 0, 0x43c9, 0x19B78FF82C94b5E517f2279f3fBF10498B039179, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, 0x78C71164356ab97D1e7FD26004E4C494f2C4076c, 0x468603D798B4AEA92e7aa06493982F22804eBbEf, 1 ether);
        // messageQueue.testDepositTransaction(4, 0, 0x43d1, 0x19B78FF82C94b5E517f2279f3fBF10498B039179, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, 0x78C71164356ab97D1e7FD26004E4C494f2C4076c, 0x468603D798B4AEA92e7aa06493982F22804eBbEf, 1 ether);


        bytes
            memory transactionInfo = hex"0000000000000001000000000000000363f95c640179b6fa94325f0216981bc7761ed46c0d35fdb0b615382d99b9af9100000000000000010fb12f57004c63d770eb02c0d377c266d087418bd61de5b45f2803b40550a32b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010fb12f57004c63d770eb02c0d377c266d087418bd61de5b45f2803b40550a32b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        bytes
            memory inclusionProof = hex"09069090006fa73851577982b97c4f1f8de826542dff64d8e8111fc918c76e1ecdc0a9d8203d393dcf0305e9186aa3c61eeaf3577597a2fe774d05e85cbfba887959ae6a2b76ce669fcef9645810f615640ca700fd6c64b9dce44e082cc2feb69e6aaaa30f7e4eef56db5b2fa7aa0243456723606ab369e8d1b596b06391faac320819440723bbe3d714da78711a61288f2a8b00efc1517161b5b422f5d8d3e52f6fc6e31ca85f3a785ea568beaf06ee071472fa4e4e8658bbd4ac59d7225966fb251025136b876374ccec9ba386f8c4e198fb097410781245c765d45256da0dfc3eab74135579dbd7b6b0e73a6db609312e56b54f97cd7a106d630015dc60b971e6906401";
        // twineChain.commitAndFinalizeTransactions(transactionInfo,inclusionProof);
        console.log("Deposit hash");
        // console.logBytes32(twineChain.demoDepositRollingHash());
    }
}
