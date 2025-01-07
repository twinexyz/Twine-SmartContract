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
import {L1TwineMessenger} from "../L1/L1TwineMessenger.sol";
import {IL1ETHGateway, L1ETHGateway} from "../L1/gateways/L1ETHGateway.sol";

contract TwineChainTest is Test {
    RoleManager roleManager;
    TwineChain public twineChain;
    L1MessageQueue public messageQueue;
    L1TwineMessenger public l1TwineMessenger;
    L1ETHGateway private gateway;
    
    address public verifier;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_OPERATIONS_HANDLER = keccak256("TWINE_OPERATIONS_HANDLER");
    

    function setUp() public {
        vm.startPrank(initialOwner);
        deal(initialOwner, 10 ether);

        verifier = address(new SP1Verifier());

        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );
        roleManager = RoleManager(roleManagerAddress);
        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.grantRole(TWINE_OPERATIONS_HANDLER, initialOwner);

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

    }

    // function testFinalizationWithCommitment() public {

    //     /********************
    //      * Preparing Input * 
    //      ********************/

    //     ITwineChain.StoredBatchInfo memory commit_info = ITwineChain.StoredBatchInfo({
    //         batchNumber: 1,
    //         batchHash: 0x9bc1bcaf54846af7e64c3e383b15ac99c04659a1f8af68310b558ac5a6854617,
    //         previousStateRoot: 0x30ef9aeb96f07ce8c486b0f932edb1ab5840b1e611930b7a451d3f839dc77980,
    //         stateRoot: 0x4ddfbf79e61b76a2b5f3aba12804745074ab12674bef9e141388a86cedd809d1,
    //         transactionRoot: 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23,
    //         receiptRoot: 0x621905d05da3a0b316acb658e7d6db3ef44e59bf597a4ac0c4436211174b94d5
    //     }); 

    //     ITwineChain.DepositReturn memory deposit_return = ITwineChain.DepositReturn({
    //         depositCount: 1,
    //         depositRollingHash: 0x4ddfbf79e61b76a2b5f3aba12804745074ab12674bef9e141388a86cedd809d1
    //     });

    //     ITwineChain.WithdrawReturn memory withdraw_return = ITwineChain.WithdrawReturn({
    //         withdrawCount: 2,
    //         withdrawRollingHash: 0x4ddfbf79e61b76a2b5f3aba12804745074ab12674bef9e141388a86cedd809d1,
    //         statusBit: "10"
    //     });

    //     ITwineChain.ChainCommitment memory chain_commitment = ITwineChain.ChainCommitment({
    //         deposit: deposit_return,
    //         withdraw: withdraw_return,
    //         otherTransactions: hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448"
    //     });

    //     ITwineChain.TransactionInfo memory transaction_info = ITwineChain.TransactionInfo({
    //         batchNumber: 1,
    //         transactionRoot: 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23,
    //         receiptRoot: 0xec0402a163738d2c8eb41a2a5b8fcd8b312cf6670cca6590fddcb28f38d35b23,
    //         ethereum: chain_commitment,
    //         solana: chain_commitment
    //     });

    //     IL1MessageQueue.MessageData memory message = IL1MessageQueue.MessageData({
    //         nonce: 1,
    //         toAddress: "to_address",
    //         l1Token: "l1_token",
    //         l2Token: "l2_token",
    //         chainId: 1,
    //         amount: "amount",
    //         blockNumber: 1
    //     });

    //     ITwineChain.FinalizeInput memory finalize_input = ITwineChain.FinalizeInput({
    //         batchNumber: 1,
    //         executionProof: hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448",
    //         inclusionProof: hex"09069090114430e527b5fbfb5f7cc7e6aff5b4ee1d7b14ef2b976f624a37e8719f4c0c262b935e8eeb3aa193d6c41cd0afa60998abe800744c05e0dcc2de676db6c7209f099aba1664892cd6a2021ccfd73d1bae7219d6e63dc9d146251e381db98edf4b1de52a6f4801ced46a470f0806006eaa58638876195f38b548ecc78dd1a1b5612b8fc84cde99bf9c215cc02a1dc30106b7563f1bfe4d02421fbea09d3c34307b189deb99ac9e3fce07cf0dbd1f382b8212376b991a94850a7c1f3a0851e1f09b1d7480851196d509f9474347e1dbbc84f34403ab542ee2374ba74f7f390f43622e59f2beb351d9f990ddc674751e062a6ee464313387f904ca395d812ac90448"
    //     });

    //     assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 0);
    //     assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 0);

    //     vm.startPrank(initialOwner);
    //     L1MessageQueue(messageQueue).testAppendDeposit(message);

    //     L1MessageQueue(messageQueue).testAppendWithdraw(message);
    //     L1MessageQueue(messageQueue).testAppendWithdraw(message);

    //     assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 1);
    //     assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 2);

    //     vm.startPrank(initialOwner);
    //     twineChain.commitBatch(commit_info, transaction_info);
    //     assertEq(twineChain.lastCommittedBatchNumber(), 1);

    //     vm.startPrank(initialOwner);
    //     twineChain.finalizeBatch(finalize_input);
    //     assertEq(twineChain.lastFinalizedBatchNumber(), 1);
        
    //     assertEq(messageQueue.nextCrossDomainDepositMessageIndex(), 0);
    //     assertEq(messageQueue.nextCrossDomainWithdrawalMessageIndex(), 0);      

    //     assertEq(messageQueue.nextCrossDomainExecutionMessageIndex(), 1);
        
    // }   
}