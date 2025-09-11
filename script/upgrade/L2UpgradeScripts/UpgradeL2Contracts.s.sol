// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ProxyAdminLib} from "../../utils/ProxyAdminLib.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {L2MsgExecutor} from "../../../src/L2/L2MsgExecutor.sol";
import {L2TwineMessenger} from "../../../src/L2/L2TwineMessenger.sol";
import {L2ETHGateway} from "../../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../../src/L2/gateways/L2GatewayRouter.sol";
import {L2CustomERC20Gateway} from "../../../src/L2/gateways/L2CustomERC20Gateway.sol";

contract UpgradeL2CustomERC20Gateway is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l2CustomERC20GatewayAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        l2CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2CustomERC20Gateway"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L2CustomERC20Gateway newL2CustomERC20Gateway = new L2CustomERC20Gateway();
        ProxyAdmin admin = l2CustomERC20GatewayAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2CustomERC20GatewayAddress),
            address(newL2CustomERC20Gateway),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL2ETHGateway is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l2ETHGatewayAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        l2ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2ETHGateway"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L2ETHGateway newL2ETHGateway = new L2ETHGateway();
        ProxyAdmin admin = l2ETHGatewayAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2ETHGatewayAddress),
            address(newL2ETHGateway),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL2GatewayRouter is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l2GatewayRouterAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        l2GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2GatewayRouter"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L2GatewayRouter newL2GatewayRouter = new L2GatewayRouter();
        ProxyAdmin admin = l2GatewayRouterAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2GatewayRouterAddress),
            address(newL2GatewayRouter),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeMessageExecutor is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l2MsgExecutorAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        l2MsgExecutorAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2MsgExecutor"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L2MsgExecutor newL2MsgExecutor = new L2MsgExecutor();
        ProxyAdmin admin = l2MsgExecutorAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2MsgExecutorAddress),
            address(newL2MsgExecutor),
            data
        );

        vm.stopBroadcast();
    }
}

contract UpgradeL2TwineMessenger is Script {
    using ProxyAdminLib for address;

    uint256 deployerPrivateKey;
    address l2TwineMessengerAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory deployedJson = vm.readFile(
            "./script/utils/twineAddresses.json"
        );

        l2TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".L2TwineMessenger"
        );
    }

    function run() external {
        bytes memory data = "";

        vm.startBroadcast(deployerPrivateKey);

        L2TwineMessenger newL2TwineMessenger = new L2TwineMessenger();
        ProxyAdmin admin = l2TwineMessengerAddress.getProxyAdmin();

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(l2TwineMessengerAddress),
            address(newL2TwineMessenger),
            data
        );

        vm.stopBroadcast();
    }
}

