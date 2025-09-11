// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import "forge-std/console.sol";

import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";

contract SetRoleManagerAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Role Manager:", twineChain.roleManager());

        twineChain.setRoleManagerAddress(roleManagerAddress);

        console.log("New Role Manager:", twineChain.roleManager());
        vm.stopBroadcast();
    }
}

contract SetChainId is Script {
    TwineChain twineChain;
    address twineChainAddress;
    uint256 chainId;
    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        chainId = vm.envUint("CHAIN_ID");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Chain ID:", twineChain.chainId());

        twineChain.setChainId(uint64(chainId));
        console.log("New Chain ID:", twineChain.chainId());

        vm.stopBroadcast();
    }
}

contract SetMessageHandlerAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;
    address messageHandlerAddress;
    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        messageHandlerAddress = vm.envAddress("MESSAGE_HANDLER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "Previous Messenger Handler Address:",
            twineChain.messageHandler()
        );

        twineChain.setMessageHandlerAddress(messageHandlerAddress);

        console.log(
            "New Messenger Handler Address:",
            twineChain.messageHandler()
        );
        vm.stopBroadcast();
    }
}

contract SetVerifierAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;
    address verifier;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);
        verifier = vm.envAddress("VERIFIER_ADDRESS");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Verifier: ", twineChain.verifier());

        twineChain.setVeriferAddress(verifier);

        console.log("New Verifier: ", twineChain.verifier());
        vm.stopBroadcast();
    }
}

contract SetProgramVkey is Script {
    TwineChain twineChain;
    address twineChainAddress;

    bytes32 refundVkey;
    bytes32 finalizeVKey;
    bytes32 l2WithdrawalVkey;
    bytes32 forcedWithdrawalVkey;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        refundVkey = vm.envBytes32("REFUND_VKEY");
        finalizeVKey = vm.envBytes32("FINALIZE_VKEY");
        l2WithdrawalVkey = vm.envBytes32("L2_WITHDRAWAL_VKEY");
        forcedWithdrawalVkey = vm.envBytes32("FORCED_WITHDRAWAL_VKEY");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("****Previous Vkeys****");
        console.log("FINALIZE VKEY: ");
        console.logBytes32(twineChain.finalizeVKey());
        console.log("REFUND VKEY: ");
        console.logBytes32(twineChain.refundVKey());
        console.log("FORCED WITHDRAWAL VKEY: ");
        console.logBytes32(twineChain.forcedWithdrawalVKey());
        console.log("L2 WITHDRAWAL VKEY: ");
        console.logBytes32(twineChain.l2WithdrawalVkey());


        twineChain.setProgramVKey(finalizeVKey, refundVkey, forcedWithdrawalVkey, l2WithdrawalVkey);

        console.log("****New Vkeys****");
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

contract SetGatewayAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;

    address ethGateway;
    address erc20Gateway;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );
        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
        twineChain = TwineChain(twineChainAddress);

        ethGateway = vm.envAddress("ETH_GATEWAY");
        erc20Gateway = vm.envAddress("ERC20_GATEWAY");
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Previous Eth Gateway Address: ", twineChain.ethGateway());
        console.log(
            "Previous ERC20 Gateway Address: ",
            twineChain.ERC20Gateway()
        );

        twineChain.setGatewayAddress(ethGateway, erc20Gateway);

        console.log("New Eth Gateway Address: ", twineChain.ethGateway());
        console.log("New ERC20 Gateway Address: ", twineChain.ERC20Gateway());
        vm.stopBroadcast();
    }
}
