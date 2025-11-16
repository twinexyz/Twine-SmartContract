// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {L2TwineMessenger} from "../../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../../src/L2/gateways/L2ETHGateway.sol";
import {RoleManager} from "../../../src/libraries/access/RoleManager.sol";
import {L2GatewayRouter} from "../../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../../src/L2/gateways/L2CustomERC20Gateway.sol";
import {TwineSystemStorage} from "../../../src/L2/TwineSystemStorage.sol";
import {TwineStandardERC20} from "../../../src/libraries/token/TwineStandardERC20.sol";

contract L2SetupScript is Script {
    RoleManager roleManager;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2TwineMessenger l2TwineMessenger;
    L2CustomERC20Gateway l2CustomERC20Gateway;
    TwineSystemStorage twineSystemStorage;
    TwineStandardERC20 solToken;
    TwineStandardERC20 ethToken;
    TwineStandardERC20 fauxCoin;

    uint256 chainIdEth;
    uint256 chainIdSolana;
    address solTokenAddress;
    address ethTokenAddress;
    address fauxCoinAddress;
    address roleManagerAddress;
    address l2MessageExecutorAddress;
    address l2ETHGatewayAddress;
    address l1ETHGatewayAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address chainAdmin;
    address twineOperationsHandler;
    address l1TwineMessengerAddress;
    address l2TwineMessengerAddress;
    address bridgingPrecompileAddress;
    address consensusPrecompileAddress;
    address twineSystemStorageAddress;
    address l1CustomERC20GatewayAddress;
    address l2CustomERC20GatewayAddress;
    address l1solTokenAddress;
    address l1FauxCoinAddress;

    function setUp() public {
        // <--------------------------- Read Json Files ---------------------------->
        string memory deployedL1Json = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        string memory deployedL2Json = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        string memory setupValues = vm.readFile(
            "./script/utils/setupValues.json"
        );

        // <-------------------- Deployed L2 Contract Addresses -------------------->
        roleManagerAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2RoleManager"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2CustomERC20Gateway"
        );

        l2ETHGatewayAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2ETHGateway"
        );

        l2GatewayRouterAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2GatewayRouter"
        );

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2TwineMessenger"
        );

        l2MessageExecutorAddress = vm.parseJsonAddress(
            deployedL2Json,
            ".L2MsgExecutor"
        );

        solTokenAddress = vm.parseJsonAddress(deployedL2Json, ".SolToken");

        ethTokenAddress = vm.parseJsonAddress(deployedL2Json, ".ETHToken");

        fauxCoinAddress = vm.parseJsonAddress(deployedL2Json, ".FauxCoin");

        // <-------------------- Deployed L1 Contract Addresses -------------------->

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1ETHGateway"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1CustomERC20Gateway"
        );

        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedL1Json,
            ".L1TwineMessenger"
        );

        l1FauxCoinAddress = vm.parseJsonAddress(deployedL1Json, ".FauxCoin");

        l1solTokenAddress = vm.parseJsonAddress(deployedL1Json, ".EthSol");


        // <-------------------- L2 Contracts -------------------->

        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );
        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        l2TwineMessenger = L2TwineMessenger(l2TwineMessengerAddress);
        solToken = TwineStandardERC20(solTokenAddress);
        ethToken = TwineStandardERC20(ethTokenAddress);
        fauxCoin = TwineStandardERC20(fauxCoinAddress);
        consensusPrecompileAddress = address(0x15);
        bridgingPrecompileAddress = address(0x16);
        twineSystemStorageAddress = address(0x17);
        twineSystemStorage = TwineSystemStorage(twineSystemStorageAddress);

        // <--------------- Setup Values --------------->

        chainIdEth = uint64(vm.parseJsonUint(setupValues, ".ChainIdEth"));
        chainIdSolana = uint64(vm.parseJsonUint(setupValues, ".ChainIdSol"));

        chainAdmin = vm.parseJsonAddress(setupValues, ".L2ChainAdmin");
        twineOperationsHandler = vm.parseJsonAddress(
            setupValues,
            ".L2TwineOperationHandler"
        );
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L2_PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // setup twine messenger address
        twineSystemStorage.setTwineMessenger(l2TwineMessengerAddress);

        //roleManager setup
        roleManager.grantRole(keccak256("CHAIN_ADMIN"), initialOwner);
        roleManager.checkRole(keccak256("CHAIN_ADMIN"), initialOwner);

        roleManager.grantRole(keccak256("CHAIN_ADMIN"), chainAdmin);
        roleManager.checkRole(keccak256("CHAIN_ADMIN"), chainAdmin);

        roleManager.grantRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            twineOperationsHandler
        );
        roleManager.grantRole(
            keccak256("TWINE_GATEWAYS"),
            l2CustomERC20GatewayAddress
        );
        roleManager.checkRole(
            keccak256("TWINE_GATEWAYS"),
            l2CustomERC20GatewayAddress
        );
        roleManager.grantRole(
            keccak256("TWINE_MESSENGER"),
            l2TwineMessengerAddress
        );
        roleManager.checkRole(
            keccak256("TWINE_MESSENGER"),
            l2TwineMessengerAddress
        );
        bytes32 tokensMinterRole = roleManager.TWINE_TOKENS_MINTER();
        roleManager.grantRole(tokensMinterRole, l2TwineMessengerAddress);
        roleManager.checkRole(tokensMinterRole, l2TwineMessengerAddress);
        bytes32 tokensBurnerRole = roleManager.TWINE_TOKENS_BURNER();
        roleManager.grantRole(tokensBurnerRole, l2CustomERC20GatewayAddress);
        roleManager.checkRole(tokensBurnerRole, l2CustomERC20GatewayAddress);
        roleManager.grantRole(tokensBurnerRole, l2TwineMessengerAddress);
        roleManager.checkRole(tokensBurnerRole, l2TwineMessengerAddress);

        //L2ETHGateway setup
        l2ETHGateway.setRoleManagerAddress(roleManagerAddress);
        l2ETHGateway.setRouterAddress(l2GatewayRouterAddress);
        l2ETHGateway.setMessengerAddress(l2TwineMessengerAddress);
        uint256[] memory GatewaychainId = new uint256[](1);
        string[] memory l1Tokens = new string[](1);
        string[] memory CounterpartGateWay = new string[](1);
        GatewaychainId[0] = chainIdEth;
        l1Tokens[0] = addressToString(l1FauxCoinAddress);
        CounterpartGateWay[0] = addressToString(l1ETHGatewayAddress);

        //L2GatewayRouter Setup
        address[] memory tokens = new address[](3);
        address[] memory gateways = new address[](3);
        tokens[0] = solTokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        tokens[0] = ethTokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        tokens[0] = fauxCoinAddress;
        gateways[0] = l2CustomERC20GatewayAddress;
        l2GatewayRouter.setRoleManagerAddress(address(roleManager));
        l2GatewayRouter.setERC20Gateway(tokens, gateways);
        l2GatewayRouter.setETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter.setDefaultERC20Gateway(l2CustomERC20GatewayAddress);

        //L2TwineMessenger
        l2TwineMessenger.setPrecompileAddress(
            consensusPrecompileAddress,
            bridgingPrecompileAddress
        );
        l2TwineMessenger.setRoleManager(roleManagerAddress);
        uint256[] memory chainIds = new uint256[](1);
        address[] memory counterpartMessenger = new address[](1);
        chainIds[0] = chainIdEth;
        counterpartMessenger[0] = l1TwineMessengerAddress;
        l2TwineMessenger.setCounterpartMessenger(
            chainIds,
            counterpartMessenger
        );
        l2TwineMessenger.setSystemStorageContract(twineSystemStorageAddress);
        l2TwineMessenger.setMsgExecutorAddress(l2MessageExecutorAddress);

        //L2CustomERC20Gateway
        l2CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2CustomERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2CustomERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);

        l2CustomERC20Gateway.updateTokenMapping(
            chainIdEth,
            fauxCoinAddress,
            addressToString(l1FauxCoinAddress)
        );

        l2CustomERC20Gateway.updateTokenMapping(
            chainIdEth,
            ethTokenAddress,
            "0x0000000000000000000000000000000000000000"
        );
        l2CustomERC20Gateway.updateTokenMapping(
            chainIdEth,
            solTokenAddress,
            addressToString(l1solTokenAddress)
        );

        l2CustomERC20Gateway.updateTokenMapping(
            chainIdSolana,
            solTokenAddress,
            "11111111111111111111111111111111"
        );


        // TODO: Map FauxCoin on Twine to FauxCoin on solana

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }

    function addressToString(
        address _address
    ) public pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}
