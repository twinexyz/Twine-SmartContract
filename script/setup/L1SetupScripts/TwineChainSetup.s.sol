// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "forge-std/Script.sol";
import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";

contract SetRoleManagerAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;
    address roleManagerAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );
        twineChain = TwineChain(twineChainAddress);

        roleManagerAddress = vm.envAddress("ROLE_MANAGER_ADDRESS");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        twineChain.setRoleManagerAddress(roleManagerAddress);
        vm.stopBroadcast();

    }

}

contract SetChainId is Script {
    TwineChain twineChain;
    address twineChainAddress;
    uint256 chainId;
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );
        twineChain = TwineChain(twineChainAddress);

        chainId = vm.envUint("CHAIN_ID");
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        twineChain.setChainId(chainId);
        vm.stopBroadcast();
    } 
}

contract SetmessageQueueAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;
    address messageQueueAddress;
    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );
        twineChain = TwineChain(twineChainAddress);

        messageQueueAddress = vm.envAddress("MESSAGE_QUEUE_ADDRESS");
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        twineChain.setMessengerQueueAddress(messageQueueAddress);
        vm.stopBroadcast();
    }
}

contract SetVerifierAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;
    address verifier;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );
        twineChain = TwineChain(twineChainAddress);
        verifier = vm.envAddress("VERIFIER_ADDRESS");

    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        twineChain.setVeriferAddress(verifier);
        vm.stopBroadcast();
    }
}  

contract SetProgramVkey is Script {
    TwineChain twineChain;
    address twineChainAddress;

    bytes32 executionVkey;
    bytes32 inclusionVkey;
    bytes32 withdrawalVkey;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );
        twineChain = TwineChain(twineChainAddress);

        executionVkey = vm.envBytes32("EXECUTION_VKEY");
        inclusionVkey = vm.envBytes32("INCLUSION_VKEY");
        withdrawalVkey = vm.envBytes32("WITHDRAWAL_VKEY");

    }
        function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        twineChain.setProgramVKey(executionVkey, inclusionVkey, withdrawalVkey);
        vm.stopBroadcast();

    }
}

contract SetGatewayAddress is Script {
    TwineChain twineChain;
    address twineChainAddress;

    address ethGateway;
    address erc20Gateway;

    function setUp() public {
        string memory deployedJson = vm.readFile("./script/utils/deployedContracts.json");
        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );
        twineChain = TwineChain(twineChainAddress);

        ethGateway = vm.envAddress("ETH_GATEWAY");
        erc20Gateway = vm.envAddress("ERC20_GATEWAY");
    }
        function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        twineChain.setGatewayAddress(ethGateway, erc20Gateway);
        vm.stopBroadcast();
    }
}