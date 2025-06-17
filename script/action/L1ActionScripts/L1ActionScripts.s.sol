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
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
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
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");

        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".L1GatewayRouter");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
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
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");

        l1ETHGatewayAddress = vm.parseJsonAddress(deployedJson, ".L1ETHGateway");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".L1MessageQueue");
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        // Read parameters dynamically 
        withdrawAmount = vm.envUint("WITHDRAW_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

     function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

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
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");

        l1ERC20TokenAddress = vm.parseJsonAddress(deployedJson, ".FauxCoin");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedJson, ".L1GatewayRouter");
        l1CustomERC20GatewayAddress = vm.parseJsonAddress(deployedJson, ".L1CustomERC20Gateway");

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
        string memory deployedL1ContractJson = vm.readFile("./script/utils/L1Addresses.json");
        string memory deployedL2ContractJson = vm.readFile("./script/utils/twineAddresses.json");

        l1ERC20TokenAddress = vm.parseJsonAddress(deployedL1ContractJson, ".FauxCoin");
        l2ERC20TokenAddress = vm.parseJsonAddress(deployedL2ContractJson, ".FauxCoin");
        l1GatewayRouterAddress = vm.parseJsonAddress(deployedL1ContractJson, ".L1GatewayRouter");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedL1ContractJson, ".L1MessageQueue");

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

contract CommitBatch is Script {
    TwineChain twineChain;
    address twineChainAddress;

    // Data required for commitment:
    uint64 startBlock;
    uint64 endBlock;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        // Read environment variables
        startBlock = uint64(vm.envUint("START_BLOCK"));
        endBlock = uint64(vm.envUint("END_BLOCK"));
        
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    
        // Extract JSON file
        string memory commitmentJson = vm.readFile("./script/utils/commitInfo.json");
        
        // Get CommitBlockInfo array length
        uint256 length = 0;
        while(true) {
            string memory indexStr = string.concat(".CommitBlockInfo[", vm.toString(length),"].blockNumber");
            try vm.parseJsonUint(commitmentJson, indexStr) returns (uint256) {
                length ++;
            } catch {
                break;
            }
        }

        // Initialize array of CommitBlockInfo
        ITwineChain.CommitBlockInfo[] memory newcommitBlockInfo = new ITwineChain.CommitBlockInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            string memory indexStr = string.concat(".CommitBlockInfo[", vm.toString(i), "]");

            newcommitBlockInfo[i] = ITwineChain.CommitBlockInfo({
                blockNumber: uint64(vm.parseJsonUint(commitmentJson, string.concat(indexStr, ".blockNumber"))),
                blockHash: vm.parseJsonBytes32(commitmentJson, string.concat(indexStr, ".blockHash")),
                transactionRoot: vm.parseJsonBytes32(commitmentJson, string.concat(indexStr, ".transactionRoot")),
                receiptRoot: vm.parseJsonBytes32(commitmentJson, string.concat(indexStr, ".receiptRoot"))
            });
        }

        vm.startBroadcast(deployerPrivateKey);
        console.log("Last finalize batch before commitment:", twineChain.lastCommittedBlockNumber());
        
        twineChain.commitBatch(startBlock, endBlock, newcommitBlockInfo);
        
        console.log("Last finalize batch after commitment:", twineChain.lastCommittedBlockNumber());
        vm.stopBroadcast();
    }
}

contract FinalizeBatch is Script {
    TwineChain twineChain;
    address twineChainAddress;

    bytes publicInputForExecution;
    bytes executionProof;
    
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        // Read environment variables
        publicInputForExecution =vm.envBytes("PUBLIC_INPUT_FOR_EXECUTION");
        executionProof = vm.envBytes("EXECUTION_PROOF");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    
 
        vm.startBroadcast(deployerPrivateKey);
        console.log("Last finalize batch before finalization:", twineChain.lastFinalizedBlockNumber());
        
        twineChain.finalizeBatch(publicInputForExecution, executionProof);
        
        console.log("Last finalize batch after finalization:", twineChain.lastFinalizedBlockNumber());
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
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        l1MessageQueueAddress = vm.parseJsonAddress(deployedJson, ".L1MessageQueue");

        twineChain = TwineChain(twineChainAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);

        // Read parameters dynamically
        transactionInfo = vm.envBytes("TRANSACTION_INFO");
        inclusionProof = vm.envBytes("INCLUSION_PROOF");
    }

     function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

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
    uint64 blockNumber;
    uint64 nonce;
    uint8 isForcedWithdrawal;
    bytes32 receiptRoot;
    string l1ReceiverAddress;
    string l1TokenAddress;
    string l2TokenAddress;
    string amount;

    bytes inclusionProof;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        // Read parameters dynamically
        chainId = uint64(vm.envUint("CHAIN_ID"));
        blockNumber =  uint64(vm.envUint("BLOCK_NUMBER"));
        nonce = uint64(vm.envUint("NONCE"));
        isForcedWithdrawal = uint8(vm.envUint("IS_FORCED"));
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
            blockNumber: blockNumber,
            nonce: nonce,
            isForcedWithdrawal: isForcedWithdrawal,
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

contract GrantRole is Script {
    RoleManager roleManager;
    address roleManagerAddress;

    string role;
    address account;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json.json");
        
        roleManagerAddress = vm.parseJsonAddress(deployedJson, ".L1RoleManager");
        roleManager = RoleManager(roleManagerAddress);

        // Read parameters dynamically
        role = vm.envString("ROLE");
        account = vm.envAddress("Account");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bytes32 encodedRole = keccak256(abi.encodePacked(role));
       
        vm.startBroadcast(deployerPrivateKey);

        roleManager.grantRole(encodedRole, account);
        roleManager.checkRole(encodedRole, account);

        vm.stopBroadcast();
    }
}

contract RevokeRole is Script {
    RoleManager roleManager;
    address roleManagerAddress;

    string role;
    address account;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/L1Addresses.json");
        
        roleManagerAddress = vm.parseJsonAddress(deployedJson, ".L1RoleManager");
        roleManager = RoleManager(roleManagerAddress);

        // Read parameters dynamically
        role = vm.envString("ROLE");
        account = vm.envAddress("Account");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        bytes32 encodedRole = keccak256(abi.encodePacked(role));
       
        vm.startBroadcast(deployerPrivateKey);

        roleManager.revokeRole(encodedRole, account);
        
        vm.stopBroadcast();
    }
}