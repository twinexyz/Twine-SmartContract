// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {TwineDVN} from "../../src/lzdvn/TwineDVN.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {TwineDVN} from "../../src/lzdvn/TwineDVN.sol";
import {MockERC20} from "../../src/test/mocks/MockERC20.sol";
import {TwineChain} from "../../src/L1/rollup/TwineChain.sol";
import {L1TwineMessenger} from "../../src/L1/L1TwineMessenger.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L1ETHGateway} from "../../src/L1/gateways/L1ETHGateway.sol";
import {L1MessageQueue} from "../../src/L1/rollup/L1MessageQueue.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {L1GatewayRouter} from "../../src/L1/gateways/L1GatewayRouter.sol";
import {L1XERC20Gateway} from "../../src/L1/gateways/L1XERC20Gateway.sol";
import {L1CustomERC20Gateway} from "../../src/L1/gateways/L1CustomERC20Gateway.sol";

contract L1ActionScript is Script {
    MockERC20 token;
    TwineDVN twineDVN;
    TwineChain twineChain;
    RoleManager roleManager;
    L1ETHGateway l1ETHGateway;
    L1MessageQueue l1MessageQueue;
    L1GatewayRouter l1GatewayRouter;
    L1XERC20Gateway l1XERC20Gateway;
    L1TwineMessenger l1TwineMessenger;
    L1CustomERC20Gateway l1CustomERC20Gateway;

    address twineChainAddress;
    address roleManagerAddress;
    address l1ETHGatewayAddress;
    address l1ERC20TokenAddress;
    address l1MessageQueueAddress;
    address l1GatewayRouterAddress;
    address l1XERC20GatewayAddress;
    address l1TwineMessengerAddress;
    address l1CustomERC20GatewayAddress;

    function setUp() public {
        string memory deployedJson = vm.readFile(
            "./script/utils/deployedContracts.json"
        );

        roleManagerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1RoleManager"
        );

        l1ETHGatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ETHGateway"
        );

        l1CustomERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1CustomERC20Gateway"
        );

        twineChainAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.TwineChain"
        );

        l1GatewayRouterAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1GatewayRouter"
        );

        l1XERC20GatewayAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1XERC20Gateway"
        );

        l1MessageQueueAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1MessageQueue"
        );

        l1TwineMessengerAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1TwineMessenger"
        );

        l1ERC20TokenAddress = vm.parseJsonAddress(
            deployedJson,
            ".Dev1.L1ERC20Token"
        );
        twineChain = TwineChain(twineChainAddress);
        l1CustomERC20Gateway = L1CustomERC20Gateway(
            l1CustomERC20GatewayAddress
        );
        roleManager = RoleManager(roleManagerAddress);
        l1ETHGateway = L1ETHGateway(l1ETHGatewayAddress);
        l1GatewayRouter = L1GatewayRouter(l1GatewayRouterAddress);
        l1XERC20Gateway = L1XERC20Gateway(l1XERC20GatewayAddress);
        l1MessageQueue = L1MessageQueue(l1MessageQueueAddress);
        l1TwineMessenger = L1TwineMessenger(l1TwineMessengerAddress);
        token = MockERC20(l1ERC20TokenAddress);
    }

    function run() external {
        bytes memory data = "";
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

          TwineChain newTwineChain = new TwineChain();
          getProxyAdmin(twineChainAddress).upgradeAndCall(
            ITransparentUpgradeableProxy(twineChainAddress),
            address(newTwineChain),
            data
        );
        bytes memory testBytes = hex"0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000249b7159576ef5e28b5d2dbcf667a34039ee1581000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002b35952d30c6da34af5a7952134226c787fc417b981b990b8f56ce210f3d8615750f2dad784e1b853e952ac8a93ebb9b217f95dd55bcfe362f354e786329e98e3b74e600000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000005101000000000000000e00009d1900000000000000000000000029c8846bef1683b32ed34c9ec68706001ff4390a00009ce1000000000000000000000000249b7159576ef5e28b5d2dbcf667a34039ee1581000000000000000000000000000000";
        uint32 dstid = 40161;
        bytes memory finalbytes = abi.encode(dstid,testBytes);
        
         TwineDVN newTwineDvn = new TwineDVN();
          getProxyAdmin(0xC500a815D49F4396d28111C3D91A2120195eBe6f).upgradeAndCall(
            ITransparentUpgradeableProxy(0xC500a815D49F4396d28111C3D91A2120195eBe6f),
            address(newTwineDvn),
            data
        );
        TwineDVN(0x952f7a8766f134817DF73301900b6A22Ae9C7250).validatePayload(finalbytes);
        TwineDVN(0x952f7a8766f134817DF73301900b6A22Ae9C7250).addLzMessageLib(0xcc1ae8Cf5D3904Cef3360A9532B477529b177cCE);
        twineChain.setEid(40161);

        token.approve(l1CustomERC20GatewayAddress, 100000);
        token.approve(l1GatewayRouterAddress, 100000);

        l1GatewayRouter.depositERC20{value: 0}(
            l1ERC20TokenAddress,
            admin,
            912,
            0
        );

        l1GatewayRouter.depositETH{value: 1 ether}(
            admin,
            1000000000000000000,
            0
        );

        twineChain.setDvn(0x952f7a8766f134817DF73301900b6A22Ae9C7250);
        twineChain.setChainsDvn(17000,0xC500a815D49F4396d28111C3D91A2120195eBe6f);
        twineChain.verifyPayload(8265,0);
        roleManager.grantRole(keccak256("CHAIN_ADMIN"), 0x5BA85D71ef9aE0EdC180a6bf5e65F0a749f062DC);
         l1TwineMessenger.setCounterpartMessenger(0x5eb3Bc0a489C5A8288765d2336659EbCA68FCd00);
        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
    function getProxyAdmin(
        address proxyAddress
    ) internal view returns (ProxyAdmin contractAdmin) {
        address proxyAdminContractAddress = Upgrades.getAdminAddress(
            address(proxyAddress)
        );
        contractAdmin = ProxyAdmin(proxyAdminContractAddress);
    }
}
