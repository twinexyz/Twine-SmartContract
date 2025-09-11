// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";

contract ViewRoleManagerAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Role Manager:", twineChain.roleManager());
        vm.stopBroadcast();
    }
}

contract ViewChainId is Script {
    TwineChain twineChain;
    address twineChainAddress;
    uint256 chainId;
    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Chain ID:", twineChain.chainId());
        vm.stopBroadcast();
    }
}

contract ViewMessageHandlerAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;
    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Messenger Handler Address:",
            twineChain.messageHandler()
        );
        vm.stopBroadcast();
    }
}

contract ViewVerifierAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Verifier: ", twineChain.verifier());
        vm.stopBroadcast();
    }
}

contract ViewProgramVkey is Script {
    TwineChain twineChain;
    address twineChainAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log(" ********** Vkeys ******** ");
        console.log("FINALIZE VKEY: ");
        console.logBytes32(twineChain.finalizeVKey());
        console.log("REFUND VKEY: ");
        console.logBytes32(twineChain.refundVKey());
        console.log("FORCED WITHDRAWAL VKEY: ");
        console.logBytes32(twineChain.forcedWithdrawalVKey());
        console.log("L2 WITHDRAWAL VKEY: ");
        console.logBytes32(twineChain.l2WithdrawalVkey());

        vm.stopBroadcast();
    }
}

contract ViewGatewayAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Eth Gateway Address: ", twineChain.ethGateway());
        console.log("ERC20 Gateway Address: ", twineChain.ERC20Gateway());
        vm.stopBroadcast();
    }
}


contract ViewLastCommittedBatchNumber is Script {
    TwineChain twineChain;
    address twineChainAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Last Committed Batch Number: ", twineChain.lastCommittedBatchNumber());
        vm.stopBroadcast();
    }
}

contract ViewLastFinalizedBatchNumber is Script {
    TwineChain twineChain;
    address twineChainAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Last Finalized Batch Number: ", twineChain.lastFinalizedBatchNumber());
        vm.stopBroadcast();
    }
}

contract ViewLastFinalizedBatchHash is Script {
        TwineChain twineChain;
    address twineChainAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Last Finalized Batch Hash: ");
        console.logBytes32(twineChain.lastFinalizedBatchHash());
        vm.stopBroadcast();
    }
}