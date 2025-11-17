// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {MockERC20} from "../../../src/test/mocks/MockERC20.sol";
import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";
import {ITwineChain} from "../../../src/L1/rollup/ITwineChain.sol";
import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageHandler} from "../../../src/L1/rollup/L1MessageHandler.sol";
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
    bytes data;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1GatewayRouter"
        );
        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1ETHGateway"
        );
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1ETHGateway = L1ETHGateway(l1GatewayRouterAddress);

        // Read parameters dynamically
        depositAmount = vm.envUint("DEPOSIT_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
        data = vm.envBytes("DATA");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log(
            "Gateway Balance before deposit",
            address(l1ETHGateway).balance
        );
        console.log("Admin Balance before deposit", admin.balance);
        l1GatewayRouter.depositETHAndCall{value: depositAmount}(
            receiver,
            depositAmount,
            0,
            data
        );
        console.log(
            "Gateway Balance after deposit",
            address(l1ETHGateway).balance
        );
        console.log("Admin Balance after deposit", admin.balance);

        vm.stopBroadcast();
    }
}

contract ForcedWithdrawETH is Script {
    L1ETHGateway l1ETHGateway;
    L1MessageHandler l1MessageHandler;

    address l1ETHGatewayAddress;
    address l1MessageHandlerAddress;

    uint256 withdrawAmount;
    address receiver;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1ETHGateway"
        );
        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1MessageHandler"
        );
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);

        // Read parameters dynamically
        withdrawAmount = vm.envUint("WITHDRAW_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        console.log(
            "Message Queue's Nonce Before withdrawal",
            l1MessageHandler.messageIndex()
        );
        vm.startBroadcast(deployerPrivateKey);

        l1ETHGateway.forcedWithdrawalETH{value: 0}(
            receiver,
            withdrawAmount,
            0,
            bytes("")
        );

        console.log(
            "Message Queue's Nonce After withdrawal",
            l1MessageHandler.messageIndex()
        );
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
    bytes data;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1ERC20TokenAddress = vm.parseJsonAddress(deployedJson, ".FauxCoin");
        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1GatewayRouter"
        );
        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1CustomERC20Gateway"
        );

        token = MockERC20(l1ERC20TokenAddress);
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );

        // Read parameters dynamically
        depositAmount = vm.envUint("DEPOSIT_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
        data = vm.envBytes("DATA");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        token.approve(l1CustomERC20GatewayAddress, 5 ether);
        token.approve(l1GatewayRouterAddress, 5 ether);

        console.log(
            "Balance of Admin Before Deposit: ",
            token.balanceOf(admin)
        );
        l1GatewayRouter.depositERC20AndCall{value: 0}(
            l1ERC20TokenAddress,
            receiver,
            depositAmount,
            0,
            data
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
    L1MessageHandler l1MessageHandler;

    address l1ERC20TokenAddress;
    address l2ERC20TokenAddress;
    address l1GatewayRouterAddress;
    address l1MessageHandlerAddress;

    address token;
    uint256 withdrawAmount;
    address receiver;

    function setUp() public {
        string memory deployedL1ContractJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        string memory deployedL2ContractJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        l1ERC20TokenAddress = vm.parseJsonAddress(
            deployedL1ContractJson,
            ".FauxCoin"
        );
        l2ERC20TokenAddress = vm.parseJsonAddress(
            deployedL2ContractJson,
            ".FauxCoin"
        );
        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedL1ContractJson,
            ".L1GatewayRouter"
        );
        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedL1ContractJson,
            ".L1MessageHandler"
        );

        l1token = MockERC20(l1ERC20TokenAddress);
        l2token = MockERC20(l2ERC20TokenAddress);
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1MessageHandler = L1MessageHandler(l1MessageHandlerAddress);

        // Read parameters dynamically
        withdrawAmount = vm.envUint("WITHDRAW_AMOUNT");
        receiver = vm.envAddress("RECEIVER");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log(
            "Message Queue's Nonce Before withdrawal",
            l1MessageHandler.messageIndex()
        );

        l1GatewayRouter.forcedWithdrawalERC20(
            l1ERC20TokenAddress,
            l2ERC20TokenAddress,
            receiver,
            withdrawAmount,
            0,
            bytes("")
        );

        console.log(
            "Message Queue's Nonce After withdrawal",
            l1MessageHandler.messageIndex()
        );
        vm.stopBroadcast();
    }
}

contract CommitGenesisBlock is Script {
    TwineChain twineChain;
    address twineChainAddress;

    bytes32 genesisBlockHash;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        genesisBlockHash = vm.envBytes32("GENESIS_BLOCK_HASH");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        twineChain.commitGenesisBlock(genesisBlockHash);

        console.log("Genesis Block batch hash");
        console.logBytes32(twineChain.committedBatch(0));

        vm.stopBroadcast();
    }
}

contract CommitAndFinalizeBatch is Script {
    TwineChain twineChain;
    address twineChainAddress;

    uint64 batchNumber;
    bytes publicValues;
    bytes executionProof;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        // Read environment variables
        batchNumber = uint64(vm.envUint("BATCH_NUMBER"));
        publicValues = vm.envBytes("PUBLIC_INPUT_FOR_EXECUTION");
        executionProof = vm.envBytes("EXECUTION_PROOF");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Last finalize batch before finalization:",
            twineChain.lastFinalizedBatchNumber()
        );

        twineChain.commitAndFinalizeBatch(
            batchNumber,
            publicValues,
            executionProof
        );

        console.log(
            "Last finalize batch after finalization:",
            twineChain.lastFinalizedBatchNumber()
        );
        vm.stopBroadcast();
    }
}

contract RefundDeposit is Script {
    TwineChain twineChain;
    address twineChainAddress;

    bytes publicValues;
    bytes refundProof;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        // Read environment variables
        publicValues = vm.envBytes("PUBLIC_INPUT_FOR_REFUND");
        refundProof = vm.envBytes("REFUND_PROOF");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");
        console.log(
            "Refund Status Before:",
            twineChain.isRefundExecuted(keccak256(publicValues))
        );

        vm.startBroadcast(deployerPrivateKey);

        console.log(
            "Refund Status After:",
            twineChain.isRefundExecuted(keccak256(publicValues))
        );
        vm.stopBroadcast();
    }
}

contract GrantRole is Script {
    RoleManager roleManager;
    address roleManagerAddress;

    string role;
    address account;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1RoleManager"
        );
        roleManager = RoleManager(roleManagerAddress);

        // Read parameters dynamically
        role = vm.envString("ROLE");
        account = vm.envAddress("Account");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");
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
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1RoleManager"
        );
        roleManager = RoleManager(roleManagerAddress);

        // Read parameters dynamically
        role = vm.envString("ROLE");
        account = vm.envAddress("Account");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        bytes32 encodedRole = keccak256(abi.encodePacked(role));

        vm.startBroadcast(deployerPrivateKey);

        roleManager.revokeRole(encodedRole, account);

        vm.stopBroadcast();
    }
}

// TODO: ADD Scripts for executeForcedWithdrawal and executeL2Withdrawal
