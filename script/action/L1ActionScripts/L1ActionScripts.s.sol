// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";
import {ITwineChain} from "../../../src/L1/rollup/ITwineChain.sol";
import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageQueue} from "../../../src/L1/rollup/L1MessageQueue.sol";
import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";
import {L1CustomERC20Gateway} from "../../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract DepositETH is Script {
    L1GatewayRouter l1GatewayRouter;
    L1ETHGateway l1ETHGateway;
    address l1GatewayRouterAddress;
    address l1ETHGatewayAddress;

    uint256 depositAmount;
    address receiver;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1GatewayRouter");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1ETHGateway");
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1ETHGateway = L1ETHGateway(l1GatewayRouterAddress);

        // Read parameters dynamically
        depositAmount = vm.envUint("DEPOSIT_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Gateway Balance before deposit", address(l1ETHGateway).balance);
        console.log("Admin Balance before deposit", admin.balance);
        l1GatewayRouter.depositETH{value: depositAmount}(
            receiver,
            depositAmount,
            0
        );
        console.log("Gateway Balance after deposit", address(l1ETHGateway).balance);
        console.log("Admin Balance after deposit", admin.balance);

        vm.stopBroadcast();
    }
}

contract ForcedWithdrawETH is Script {
    L1ETHGateway l1ETHGateway;
    L1MessageQueue l1MessageQueue;

    address l1ETHGatewayAddress;
    address l1MessageQueueAddress;

    uint256 withdrawAmount;
    address receiver;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1ETHGateway");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1MessageQueue");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        // Read parameters dynamically 
        withdrawAmount = vm.envUint("WITHDRAW_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

     function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        console.log("Withdraw Message Queue Before withdrawal", l1MessageQueue.nextCrossDomainWithdrawalMessageIndex());
        vm.startBroadcast(deployerPrivateKey);

        l1ETHGateway.forcedWithdrawalETH{value: 0}(
            receiver,
            withdrawAmount,
            0,
            bytes("")
        );

        console.log("Withdraw Message Queue After withdrawal", l1MessageQueue.nextCrossDomainWithdrawalMessageIndex());
        vm.stopBroadcast();
    }
}

contract DepositERC20 is Script {
    MockERC20 token;
    L1GatewayRouter l1GatewayRouter;
    L1CustomERC20Gateway l1CustomERC20Gateway;
    
    address l1ERC20TokenAddress;
    address l1GatewayRouterAddress;
    address l1CustomERC20GatewayAddress;

    uint256 depositAmount;
    address receiver;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        l1ERC20TokenAddress = vm.parseJsonAddress(deployedJson, ".Dev1.JGToken");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1GatewayRouter");
        l1CustomERC20GatewayAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1CustomERC20Gateway");

        token = MockERC20(l1ERC20TokenAddress); 
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1CustomERC20Gateway = L1CustomERC20Gateway(l1CustomERC20GatewayAddress);

        // Read parameters dynamically
        depositAmount = vm.envUint("DEPOSIT_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

    function run() external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        token.mint(admin, 10 ether);
        token.approve(l1CustomERC20GatewayAddress, 5 ether);
        token.approve(l1GatewayRouterAddress, 5 ether);

        console.log("Balance of Admin Before Deposit: ", token.balanceOf(admin));
        l1GatewayRouter.depositERC20{value: 0}(
            l1ERC20TokenAddress,
            receiver,
            depositAmount,
            0
        );
        console.log("Balance of Admin After Deposit: ", token.balanceOf(admin));
        // Stop broadcasting transactions
        vm.stopBroadcast();

    }
}

contract ForcedWithdrawERC20 is Script {
    MockERC20 l1token;
    MockERC20 l2token;
    L1GatewayRouter l1GatewayRouter;
    L1MessageQueue l1MessageQueue;

    address l1ERC20TokenAddress;
    address l2ERC20TokenAddress;
    address l1GatewayRouterAddress;
    address l1MessageQueueAddress;

    uint256 withdrawAmount;
    address receiver;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        l1ERC20TokenAddress = vm.parseJsonAddress(deployedJson, ".Dev1.JGToken");
        l2ERC20TokenAddress = vm.parseJsonAddress(deployedJson, ".Twine.JGToken");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1GatewayRouter");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1MessageQueue");

        l1token = MockERC20(l1ERC20TokenAddress); 
        l2token = MockERC20(l2ERC20TokenAddress); 
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        // Read parameters dynamically
        withdrawAmount = vm.envUint("WITHDRAW_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Withdraw Message Queue Before withdrawal", l1MessageQueue.nextCrossDomainWithdrawalMessageIndex());

        l1GatewayRouter.forcedWithdrawalERC20(
            l1ERC20TokenAddress,
            l2ERC20TokenAddress,
            receiver,
            withdrawAmount,
            0,
            bytes("")
        );
        
        console.log("Withdraw Message Queue After withdrawal", l1MessageQueue.nextCrossDomainWithdrawalMessageIndex());
        vm.stopBroadcast();

    }

}

contract CommitAndFinalizeBatch is Script {
    TwineChain twineChain;
    address twineChainAddress;

    // Data required for commitment:
    uint64 batchNumber;
    bytes32 batchHash;
    bytes32 previousStateRoot;
    bytes32 stateRoot;
    bytes32 transactionRoot;
    bytes32 receiptRoot;

    bytes executionProof;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".Dev1.TwineChain");
        twineChain = TwineChain(twineChainAddress);

        // Read parameters dynamically
        batchNumber = uint64(vm.envUint("BATCH_NUMBER"));
        batchHash = vm.envBytes32("BATCH_HASH");
        previousStateRoot = vm.envBytes32("PREVIOUS_STATE_ROOT");
        stateRoot = vm.envBytes32("STATE_ROOT");
        transactionRoot = vm.envBytes32("TRANSACTION_ROOT");
        receiptRoot = vm.envBytes32("RECEIPT_ROOT");

        executionProof = vm.envBytes("EXECUTION_PROOF");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        // Prepare Input
        ITwineChain.StoredBatchInfo memory  commitInfo = ITwineChain.StoredBatchInfo({
            batchNumber: batchNumber,
            batchHash: batchHash,
            previousStateRoot: previousStateRoot,
            stateRoot: stateRoot,
            transactionRoot: transactionRoot,
            receiptRoot: receiptRoot
        });

        vm.startBroadcast(deployerPrivateKey);
        console.log("Last finalize batch before commitment:", twineChain.lastFinalizedBatchNumber());

        twineChain.commitAndFinalizeBatch(commitInfo, executionProof);

        console.log("Last finalize batch after commitment:", twineChain.lastFinalizedBatchNumber());
        vm.stopBroadcast();
    }
}

contract commitAndFinalizeTransaction is Script {
    TwineChain twineChain;
    L1MessageQueue l1MessageQueue;

    address twineChainAddress;
    address l1MessageQueueAddress;

    // data required for transaction finalization
    bytes transactionInfo;
    bytes inclusionProof;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".Dev1.TwineChain");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".Dev1.L1MessageQueue");

        twineChain = TwineChain(twineChainAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        // Read parameters dynamically
        transactionInfo = vm.envBytes("TRANSACTION_INFO");
        inclusionProof = vm.envBytes("INCLUSION_PROOF");
    }

     function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        console.log("Deposit Message Queue Before Finalization: ", l1MessageQueue.nextCrossDomainDepositMessageIndex());

        twineChain.commitAndFinalizeTransactions(transactionInfo, inclusionProof);

        console.log("Deposit Message Queue After Finalization: ", l1MessageQueue.nextCrossDomainDepositMessageIndex());
        vm.stopBroadcast();

    }
}

contract finalizeWithdrawal is Script {
    TwineChain twineChain;
    address twineChainAddress;

    // Data required for finalization
    uint64 chainId;
    uint64 batchNumber;
    uint64 nonce;
    uint8 isForced;
    bytes32 receiptRoot;
    string l1ReceiverAddress;
    string l1TokenAddress;
    string l2TokenAddress;
    string amount;

    bytes inclusionProof;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".Dev1.TwineChain");
        twineChain = TwineChain(twineChainAddress);

        // Read parameters dynamically
        chainId = uint64(vm.envUint("CHAIN_ID"));
        batchNumber = uint64(vm.envUint("BATCH_NUMBER"));
        nonce = uint64(vm.envUint("NONCE"));
        isForced = uint8(vm.envUint("IS_FORCED"));
        receiptRoot = vm.envBytes32("RECEIPT_ROOT");
        l1ReceiverAddress = vm.envString("L1_RECEIVER_ADDRESS");
        l1TokenAddress = vm.envString("L1_TOKEN_ADDRESS");
        l2TokenAddress = vm.envString("L2_TOKEN_ADDRESS");
        amount = vm.envString("AMOUNT");
        inclusionProof = vm.envBytes("INCLUSION_PROOF");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        // Prepare Input
        ITwineChain.WithdrawalPublicInput memory publicInput = ITwineChain.WithdrawalPublicInput({
            chainId: chainId,
            batchNumber: batchNumber,
            nonce: nonce,
            isForced: isForced,
            receiptRoot: receiptRoot,
            l1ReceiverAddress: l1ReceiverAddress,
            l1TokenAddress: l1TokenAddress,
            l2TokenAddress: l2TokenAddress,
            amount: amount
        });

        ITwineChain.FinalizeWithdrawalInput memory withdrawalInput = ITwineChain.FinalizeWithdrawalInput({
            publicInput: publicInput,
            inclusionProof: inclusionProof
        });

        vm.startBroadcast(deployerPrivateKey);
        console.log("Admin Balance before deposit", admin.balance);

        twineChain.finalizeWithdrawal(withdrawalInput);
        
        console.log("Admin Balance after deposit", admin.balance);
        vm.stopBroadcast();
    }
}