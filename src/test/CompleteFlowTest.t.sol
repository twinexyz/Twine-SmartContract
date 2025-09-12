/*
    Complete flow tests:
        1. Setup the contracts requirements
        2. Deposit Native and ECR20 token
        3. Withdraw Native and ERC20 token
        4. Commit a batch
        5. Finalize a batch
        6. Take deposit refund
        7. Finalize Withdrawal Execution
    
    -> This is a complete Flow test for optimistic flow, edgecases are tested on respective test files.
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";

import {MockERC20} from "./mocks/MockERC20.sol";
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
import {TwineTypes} from "../libraries/types/TwineTypes.sol";

contract CompleteFlowTest is Test {
    error ErrorZeroAddress();
    MockERC20 l1Token;
    MockERC20 l2Token;
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
    bytes32 withdrawalVKey;

    function setUp() public {
        vm.startPrank(admin);
        newMessageHandler = makeAddr("newMessageHandler");
        newVerifierAddress = makeAddr("newVerifierAddress");
        finalizeVKey = keccak256("finalizeVKey");
        refundVKey = keccak256("refundVKey");
        withdrawalVKey = keccak256("withdrawalVKey");

        deal(admin, 20 ether);

        verifier = address(new SP1Verifier());

        // Deploy Tokens
        l1Token = new MockERC20("Mock L1", "ML1");
        l2Token = new MockERC20("Mock L2", "ML2");
        l1Token.mint(admin, 100000);
        console.logAddress(address(l1Token));
        console.logAddress(address(l2Token));
        // Initialize roleManager
        address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (admin))
        );
        roleManager = RoleManager(roleManagerAddress);
        roleManager.grantRole(CHAIN_ADMIN, admin);
        roleManager.grantRole(TWINE_OPERATIONS_HANDLER, admin);

        // Initialize GatewayRouter
        address L1GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L1GatewayRouter.sol",
            msg.sender,
            abi.encodeCall(
                L1GatewayRouter.initialize,
                (address(0), address(0), address(roleManager))
            )
        );
        router = L1GatewayRouter(L1GatewayRouterAddress);

        // Initialize L1MessageHandler
        address L1MessageHandlerAddress = Upgrades.deployTransparentProxy(
            "L1MessageHandler.sol",
            msg.sender,
            abi.encodeCall(
                L1MessageHandler.initialize,
                (0, address(0), address(roleManager))
            )
        );

        messageHandler = L1MessageHandler(L1MessageHandlerAddress);

        // Initialize TwineChain
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

        // setup ETH Gateway
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
        ethGateway.setL2TokenAddress(
            0x19B78FF82C94b5E517f2279f3fBF10498B039179
        );

        // Setup ERC20 Gateway
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
        erc20Gateway.updateTokenMapping(address(l1Token), address(l2Token));

        //setup ethGateway, erc20Gateway and router;
        vm.startPrank(admin);
        router.setETHGateway(address(ethGateway));
        router.setDefaultERC20Gateway(address(erc20Gateway));
        ethGateway.setRoleManagerAddress(address(roleManager));
        erc20Gateway.setRoleManagerAddress(address(roleManager));

        // SetUp Message Handler
        messageHandler.setMessengerAddress(address(l1TwineMessenger));
        messageHandler.setChainId(1700);
        messageHandler.setRoleManager(address(roleManager));

        // SetUp Twine Chain
        twineChain.setChainId(1700);
        twineChain.setRoleManagerAddress(address(roleManager));
        twineChain.setMessageHandlerAddress(address(messageHandler));
        twineChain.setGatewayAddress(
            address(ethGateway),
            address(erc20Gateway)
        );

        // SetUp Messenger
        l1TwineMessenger.setMessageHandlerAddress(address(messageHandler));
        l1TwineMessenger.setRollupAddress(address(twineChain));

        roleManager.grantRole(TWINE_GATEWAYS, address(ethGateway));
        roleManager.grantRole(TWINE_GATEWAYS, address(erc20Gateway));
        roleManager.grantRole(TWINE_CHAIN, address(twineChain));
        vm.stopPrank();
    }

    /***************
     * Deposit ETH *
     **************/
    function testDepositEth(uint256 depositAmount) internal {
        assertEq(messageHandler.messageIndex(), 0);
        assertEq(address(ethGateway).balance, 0 ether);

        vm.startPrank(admin);
        ethGateway.depositETH{value: depositAmount}(admin, depositAmount, 0);

        assertEq(address(ethGateway).balance, depositAmount);
        assertEq(messageHandler.messageIndex(), 1);

        console.log("ETH Deposit Successful");
    }

    /**********************
     * Force Withdraw ETH *
     *********************/
    function testForcedWithdrawEth(uint256 withdrawAmount) internal {
        vm.startPrank(admin);

        ethGateway.forcedWithdrawalETH(admin, withdrawAmount, 0, new bytes(0));

        assertEq(messageHandler.messageIndex(), 2);

        console.log("ETH ForcedWithdraw Successful");
    }

    /*****************
     * Deposit ERC20 *
     ****************/
    function testDepositERC20(uint256 depositAmount) internal {
        vm.startPrank(admin);

        assertEq(l1Token.balanceOf(address(erc20Gateway)), 0);

        l1Token.approve(address(erc20Gateway), 100000);
        erc20Gateway.depositERC20(address(l1Token), admin, depositAmount, 0);

        assertEq(l1Token.balanceOf(address(erc20Gateway)), depositAmount);
        assertEq(messageHandler.messageIndex(), 3);

        console.log("ERC20 Deposit Successful");
    }

    /************************
     * Force Withdraw ERC20 *
     ***********************/
    function testForcedWithdrawERC20(uint256 withdrawAmount) internal {
        erc20Gateway.forcedWithdrawalERC20(
            address(l1Token),
            address(l2Token),
            admin,
            withdrawAmount,
            0,
            new bytes(0)
        );

        assertEq(messageHandler.messageIndex(), 4);

        console.log("ERC20 Forced Withdraw Successful");
    }


    /******************************
     *  Commit And Finalize Batch *
     *****************************/
    function testCommitAndFinalizeBatch(
        bytes32 genesisBlockHash,
        bytes32 batchHash,
        uint64 batchNumber
    ) internal {
        // Commit Genesis Block
        twineChain.commitGenesisBlock(genesisBlockHash);

        assertEq(twineChain.lastFinalizedBatchHash(), genesisBlockHash);
        assertEq(twineChain.lastCommittedBatchNumber(), 0);
        assert(twineChain.isGenesisBlockCommitted());

        uint64 totalEthMsgHandledOnTwine = 3;
        uint64 totalSolanaMsgHandledOnTwine = 2;
        bytes memory publicValuesForFinalization = abi.encodePacked(
            genesisBlockHash,
            batchHash,
            totalEthMsgHandledOnTwine,
            totalSolanaMsgHandledOnTwine
        );

        twineChain.commitAndFinalizeBatch(
            batchNumber,
            publicValuesForFinalization,
            publicValuesForFinalization
        );
        assertEq(twineChain.committedBatch(batchNumber), batchHash);
        assertEq(twineChain.lastCommittedBatchNumber(), 1);
        assertEq(twineChain.lastFinalizedBatchNumber(), 1);
        assertEq(twineChain.lastFinalizedBatchHash(), batchHash);
        assertEq(twineChain.finalizedBatch(batchNumber), batchHash);

        console.log("Batch Commitment And Finalization Successful");
    }

    /*************************
     * Refund Deposit Native *
     ************************/
    function testRefundDepositETH(
        bytes32 batchHash,
        uint64 batchNumber,
        uint256 depositAmount
    ) internal {
        ITwineChain.L1OriginTxPublicValues memory publicValuesData = ITwineChain
            .L1OriginTxPublicValues({
                batchHash: batchHash,
                batchNumber: batchNumber,
                txnType: ITwineChain.TransactionType.Deposit,
                nonce: 1,
                chainId: 1700,
                blockNumber: 100,
                messageHash: keccak256(new bytes(0)),
                fromAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                toAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                l1Token: "0x0000000000000000000000000000000000000000",
                l2Token: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                amount: "5000000000000000000"
            });

        bytes memory publicValues = abi.encodePacked(
            publicValuesData.batchHash,
            publicValuesData.batchNumber,
            publicValuesData.txnType,
            publicValuesData.nonce,
            publicValuesData.chainId,
            publicValuesData.blockNumber,
            publicValuesData.messageHash,
            publicValuesData.fromAddress,
            publicValuesData.toAddress,
            publicValuesData.l1Token,
            publicValuesData.l2Token,
            publicValuesData.amount
        );

        uint256 adminBalanceBeforeFunctionCall = admin.balance;
        uint256 gatewayBalanceBeforeFunctionCall = address(ethGateway).balance;

        twineChain.refundDeposit(publicValues, publicValues);

        uint256 adminBalanceAfterFunctionCall = admin.balance;
        uint256 gatewayBalanceAfterFunctionCall = address(ethGateway).balance;

        assertEq(
            adminBalanceAfterFunctionCall - adminBalanceBeforeFunctionCall,
            depositAmount
        );
        assertEq(
            gatewayBalanceBeforeFunctionCall - gatewayBalanceAfterFunctionCall,
            depositAmount
        );

        console.log("ETH Refund Successful");
    }

    /************************************
     * Execute Forced Withdrawal Native *
     ***********************************/
    function testExecuteForcedWithdrawETH(
        bytes32 batchHash,
        uint64 batchNumber,
        uint256 withdrawAmount
    ) internal {
        // Doing a deposit so that there is enough balance in gateway to withdraw
        ethGateway.depositETH{value: 5 ether}(admin, 5 ether, 0);

        ITwineChain.L1OriginTxPublicValues memory publicValuesData = ITwineChain
            .L1OriginTxPublicValues({
                batchHash: batchHash,
                batchNumber: batchNumber,
                txnType: ITwineChain.TransactionType.Withdraw,
                nonce: 2,
                chainId: 1700,
                blockNumber: 100,
                messageHash: keccak256(new bytes(0)),
                fromAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                toAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                l1Token: "0x0000000000000000000000000000000000000000",
                l2Token: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                amount: "1000000000000000000"
            });

        bytes memory publicValues = abi.encodePacked(
            publicValuesData.batchHash,
            publicValuesData.batchNumber,
            publicValuesData.txnType,
            publicValuesData.nonce,
            publicValuesData.chainId,
            publicValuesData.blockNumber,
            publicValuesData.messageHash,
            publicValuesData.fromAddress,
            publicValuesData.toAddress,
            publicValuesData.l1Token,
            publicValuesData.l2Token,
            publicValuesData.amount
        );

        uint256 adminBalanceBeforeFunctionCall = admin.balance;
        uint256 gatewayBalanceBeforeFunctionCall = address(ethGateway).balance;

        twineChain.executeForcedWithdrawal(publicValues, publicValues);

        uint256 adminBalanceAfterFunctionCall = admin.balance;
        uint256 gatewayBalanceAfterFunctionCall = address(ethGateway).balance;

        assertEq(
            adminBalanceAfterFunctionCall - adminBalanceBeforeFunctionCall,
            withdrawAmount
        );
        assertEq(
            gatewayBalanceBeforeFunctionCall - gatewayBalanceAfterFunctionCall,
            withdrawAmount
        );

        console.log("ETH forced Withdrawal Execution Successful");
    }

    /************************
     * Refund Deposit ERC20 *
     ***********************/
    function testRefundDepositERC20(
        bytes32 batchHash,
        uint64 batchNumber,
        uint256 depositAmount
    ) internal {
        ITwineChain.L1OriginTxPublicValues memory publicValuesData = ITwineChain
            .L1OriginTxPublicValues({
                batchHash: batchHash,
                batchNumber: batchNumber,
                txnType: ITwineChain.TransactionType.Deposit,
                nonce: 3,
                chainId: 1700,
                blockNumber: 100,
                messageHash: keccak256(new bytes(0)),
                fromAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                toAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                l1Token: "0x62323ec6c891daa8e432a6578c9c0b4c0db0356b",
                l2Token: "0xca6910b7de8614251a027e4513e728baa693360b",
                amount: "10"
            });

        bytes memory publicValues = abi.encodePacked(
            publicValuesData.batchHash,
            publicValuesData.batchNumber,
            publicValuesData.txnType,
            publicValuesData.nonce,
            publicValuesData.chainId,
            publicValuesData.blockNumber,
            publicValuesData.messageHash,
            publicValuesData.fromAddress,
            publicValuesData.toAddress,
            publicValuesData.l1Token,
            publicValuesData.l2Token,
            publicValuesData.amount
        );

        uint256 adminBalanceBeforeFunctionCall = l1Token.balanceOf(admin);
        uint256 gatewayBalanceBeforeFunctionCall = l1Token.balanceOf(
            address(erc20Gateway)
        );

        twineChain.refundDeposit(publicValues, publicValues);

        uint256 adminBalanceAfterFunctionCall = l1Token.balanceOf(admin);
        uint256 gatewayBalanceAfterFunctionCall = l1Token.balanceOf(
            address(erc20Gateway)
        );

        assertEq(
            adminBalanceAfterFunctionCall - adminBalanceBeforeFunctionCall,
            depositAmount
        );
        assertEq(
            gatewayBalanceBeforeFunctionCall - gatewayBalanceAfterFunctionCall,
            depositAmount
        );

        console.log("ERC20 Refund Successful");
    }

    /***********************************
     * Execute Forced Withdrawal ERC20 *
     **********************************/
    function testExecuteForcedWithdrawERC20(
        bytes32 batchHash,
        uint64 batchNumber,
        uint256 withdrawAmount
    ) internal {
        // Doing a deposit so that there is enough balance in gateway to withdraw
        erc20Gateway.depositERC20(address(l1Token), admin, 10, 0);

        ITwineChain.L1OriginTxPublicValues memory publicValuesData = ITwineChain
            .L1OriginTxPublicValues({
                batchHash: batchHash,
                batchNumber: batchNumber,
                txnType: ITwineChain.TransactionType.Withdraw,
                nonce: 4,
                chainId: 1700,
                blockNumber: 100,
                messageHash: keccak256(new bytes(0)),
                fromAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                toAddress: "0x19b78ff82c94b5e517f2279f3fbf10498b039179",
                l1Token: "0x62323ec6c891daa8e432a6578c9c0b4c0db0356b",
                l2Token: "0xca6910b7de8614251a027e4513e728baa693360b",
                amount: "10"
            });

        bytes memory publicValues = abi.encodePacked(
            publicValuesData.batchHash,
            publicValuesData.batchNumber,
            publicValuesData.txnType,
            publicValuesData.nonce,
            publicValuesData.chainId,
            publicValuesData.blockNumber,
            publicValuesData.messageHash,
            publicValuesData.fromAddress,
            publicValuesData.toAddress,
            publicValuesData.l1Token,
            publicValuesData.l2Token,
            publicValuesData.amount
        );

        uint256 adminBalanceBeforeFunctionCall = l1Token.balanceOf(admin);
        uint256 gatewayBalanceBeforeFunctionCall = l1Token.balanceOf(
            address(erc20Gateway)
        );

        twineChain.executeForcedWithdrawal(publicValues, publicValues);

        uint256 adminBalanceAfterFunctionCall = l1Token.balanceOf(admin);
        uint256 gatewayBalanceAfterFunctionCall = l1Token.balanceOf(
            address(erc20Gateway)
        );

        assertEq(
            adminBalanceAfterFunctionCall - adminBalanceBeforeFunctionCall,
            withdrawAmount
        );
        assertEq(
            gatewayBalanceBeforeFunctionCall - gatewayBalanceAfterFunctionCall,
            withdrawAmount
        );

        console.log("ERC20 forced Withdrawal Execution Successful");
    }

    function testTheWholeFlow() public {
        vm.roll(100);

        uint256 depositAmountEth = 5 ether;
        uint256 withdrawAmountEth = 1 ether;
        uint256 depositAmountErc20 = 10;
        uint256 withdrawAmountErc20 = 10;
        bytes32 genesisBlockHash = bytes32(0);
        uint64 batchNumber = 1;
        bytes32 batchHash = hex"8a58ec38439a3ccc22aaf10ee418aca264cd1bc16c5bab8f0378e9697210e8b5";

        testDepositEth(depositAmountEth);

        testForcedWithdrawEth(withdrawAmountEth);

        testDepositERC20(depositAmountErc20);

        testForcedWithdrawERC20(withdrawAmountErc20);

        testCommitAndFinalizeBatch(genesisBlockHash, batchHash, batchNumber);

        testRefundDepositETH(batchHash, batchNumber, depositAmountEth);

        testExecuteForcedWithdrawETH(batchHash, batchNumber, withdrawAmountEth);

        testRefundDepositERC20(batchHash, batchNumber, depositAmountErc20);

        testExecuteForcedWithdrawERC20(batchHash, batchNumber, withdrawAmountErc20);
    }
}