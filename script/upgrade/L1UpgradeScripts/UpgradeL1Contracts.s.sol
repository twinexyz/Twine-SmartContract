// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ProxyAdminLib} from "../../utils/ProxyAdminLib.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {TwineChain} from "../../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../../src/L1/L1TwineMessenger.sol";
import {L1ETHGateway} from "../../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageHandler} from "../../../src/L1/rollup/L1MessageHandler.sol";
import {L1GatewayRouter} from "../../../src/L1/gateways/L1GatewayRouter.sol";
import {L1CustomERC20Gateway} from "../../../src/L1/gateways/L1CustomERC20Gateway.sol";

import {L1ERC20} from "../../../src/libraries/token/L1ERC20.sol";

contract UpgradeL1CustomERC20Gateway is Script {
    using ProxyAdminLib for address;

    address l1CustomERC20GatewayAddress;
    uint256 deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1CustomERC20Gateway"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L1CustomERC20Gateway newL1CustomERC20Gateway = new L1CustomERC20Gateway();
        ProxyAdmin admin = l1CustomERC20GatewayAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l1CustomERC20GatewayAddress),
            address(newL1CustomERC20Gateway),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL1ETHGateway is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l1ETHGatewayAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1ETHGateway"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L1ETHGateway newL1ETHGateway = new L1ETHGateway();
        ProxyAdmin admin = l1ETHGatewayAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l1ETHGatewayAddress),
            address(newL1ETHGateway),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL1GatewayRouter is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l1GatewayRouterAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1GatewayRouter"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L1GatewayRouter newL1GatewayRouter = new L1GatewayRouter();
        ProxyAdmin admin = l1GatewayRouterAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l1GatewayRouterAddress),
            address(newL1GatewayRouter),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL1MessageHandler is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l1MessageHandlerAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1MessageHandlerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1MessageHandler"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L1MessageHandler newL1MessageHandler = new L1MessageHandler();
        ProxyAdmin admin = l1MessageHandlerAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l1MessageHandlerAddress),
            address(newL1MessageHandler),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeTwineChain is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address twineChainAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        twineChainAddress = vm.parseJsonAddress(deployedJson, ".TwineChain");
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        TwineChain newTwineChain = new TwineChain();
        ProxyAdmin admin = twineChainAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(twineChainAddress),
            address(newTwineChain),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL1TwineMessenger is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l1TwineMessengerAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L1TwineMessenger newL1TwineMessenger = new L1TwineMessenger();
        ProxyAdmin admin = l1TwineMessengerAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l1TwineMessengerAddress),
            address(newL1TwineMessenger),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL1Token is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l1TokenAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/L1Addresses.json"
        );

        l1TokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".L1TwineMessenger"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L1ERC20 newtoken = new L1ERC20();
        ProxyAdmin admin = l1TokenAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l1TokenAddress),
            address(newtoken),
            data
        );

        vm.stopBroadcast();
    }
}
