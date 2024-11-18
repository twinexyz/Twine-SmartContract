// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {L2CustomERC20Gateway} from "../../src/L2/gateways/L2CustomERC20Gateway.sol";
import {L2ETHGateway} from "../../src/L2/gateways/L2ETHGateway.sol";
import {L2GatewayRouter} from "../../src/L2/gateways/L2GatewayRouter.sol";
import {L2XERC20Gateway} from "../../src/L2/gateways/L2XERC20Gateway.sol";
import {L2TwineMessenger} from "../../src/L2/L2TwineMessenger.sol";
import {RoleManager} from "../../src/libraries/access/RoleManager.sol";
import {MockERC20} from "../../src/test/mocks/MockERC20.sol";

contract L2SetupScript is Script {

    RoleManager roleManager;
    L2CustomERC20Gateway l2CustomERC20Gateway;
    L2ETHGateway l2ETHGateway;
    L2GatewayRouter l2GatewayRouter;
    L2XERC20Gateway l2XERC20Gateway;

    L2TwineMessenger l2TwineMessenger;
    MockERC20 token;

    address l2CustomERC20GatewayAddress;
    address roleManagerAddress;
    address l2ETHGatewayAddress;
    address l2GatewayRouterAddress;
    address l2XERC20GatewayAddress;
    address l2MessageQueueAddress;
    address l2TwineMessengerAddress;
    address tokenAddress;
    address l1ERC20TokenAddress;
    address l1EthGatewayAddress;
    address l2ERC20TokenAddress;
    address l1CustomERC20GatewayAddress;
    uint256 chainIdOne;

    function setUp() public {
     
        // l2CustomERC20GatewayAddress = 0x2f8AA9b0cFbd594f719CcEBFf85628cc04B4Cbd8;
        // roleManagerAddress = 0x949D36f9c83372023FDA628A2e06c13CD51617a2;
        // l2ETHGatewayAddress = 0xb3EA4401e1e32D12AB31D588A31A658733D99241;
        // l2GatewayRouterAddress = 0x4EA6E2b7D4204316c77C502fdAd698d73d5B93Ca;
        // l2XERC20GatewayAddress = 0x20843722Da939972b8D10dD94BF77050b2518F67;

        // l2TwineMessengerAddress = 0xb74F7b21FD6fFD57277a1D171700508Ea6ac318d;
        // l2ERC20TokenAddress = 0x8b82485457dAF46762dc35D98Fb4180487dFC4dE;
        // l1ERC20TokenAddress1 = 0x1764a35208973E4eF73AEc203b9A9bA7b0e898D6;
        // l1ERC20TokenAddress2 = 0x3F22d27e4b8637CB430d7371D121dd37febE3C71;
        // l1EthGatewayAddress1 = 0x8964AF4674819DfeFebA069b29849dF0a478c2f0;
        // l1EthGatewayAddress2 = 0x81C8502341bD44913f4F29Bf4f07F9f019BC67FA;
        // l1CustomERC20GatewayAddress = 0xa0D99e5C5ba217773abCF5C8a82afd5193B55B34;
        // chainIdOne = 17000;

        l2CustomERC20GatewayAddress = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
        roleManagerAddress = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        l2ETHGatewayAddress = 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6;
        l2GatewayRouterAddress = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
        l2XERC20GatewayAddress = 0x610178dA211FEF7D417bC0e6FeD39F05609AD788;

        l2TwineMessengerAddress = 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0;
        l2ERC20TokenAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        l1ERC20TokenAddress = 0x1764a35208973E4eF73AEc203b9A9bA7b0e898D6;
        l1EthGatewayAddress = 0x81C8502341bD44913f4F29Bf4f07F9f019BC67FA;
        l1CustomERC20GatewayAddress = 0xa0D99e5C5ba217773abCF5C8a82afd5193B55B34;
        chainIdOne = 17000;

  
        l2CustomERC20Gateway = L2CustomERC20Gateway(
            l2CustomERC20GatewayAddress
        );
        roleManager = RoleManager(roleManagerAddress);
        l2ETHGateway = L2ETHGateway(l2ETHGatewayAddress);
        l2GatewayRouter = L2GatewayRouter(l2GatewayRouterAddress);
        l2XERC20Gateway = L2XERC20Gateway(l2XERC20GatewayAddress);
 
        l2TwineMessenger = L2TwineMessenger(l2TwineMessengerAddress);
        token = MockERC20(l2ERC20TokenAddress);
        
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address initialOwner = vm.addr(deployerPrivateKey);
        // StErt broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        roleManager.grantRole(
            keccak256("CHAIN_ADMIN"),
            initialOwner
        );
        roleManager.checkRole(
            keccak256("CHAIN_ADMIN"),
            initialOwner
        );
        roleManager.grantRole(
            keccak256("CHAIN_ADMIN"),
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );
        roleManager.grantRole(
            keccak256("TWINE_OPERATIONS_HANDLER"),
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );

         address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);
        tokens[0] = l2ERC20TokenAddress;
        gateways[0] = l2CustomERC20GatewayAddress;

        roleManager.grantRole(keccak256("CHAIN_ADMIN"), initialOwner);

        l2GatewayRouter.setRoleManagerAddress(address(roleManager));
        l2GatewayRouter.setERC20Gateway(tokens, gateways);
        l2GatewayRouter.setETHGateway(l2CustomERC20GatewayAddress);
        l2GatewayRouter.setDefaultERC20Gateway(l2ETHGatewayAddress);

        l2CustomERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2CustomERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2CustomERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);
        l2CustomERC20Gateway.updateTokenMapping(
            chainIdOne,
            l2ERC20TokenAddress,
            l1ERC20TokenAddress
        );
    
        uint256[] memory chainId = new uint256[](1);
        address[] memory erc20CounterpartGateWay = new address[](1);
        chainId[0] = chainIdOne;
        erc20CounterpartGateWay[0] = l1CustomERC20GatewayAddress;
        l2CustomERC20Gateway.setCounterpartGateway(
            chainId,
            erc20CounterpartGateWay
        );

        l2XERC20Gateway.setRoleManagerAddress(roleManagerAddress);
        l2XERC20Gateway.setRouterAddress(l2GatewayRouterAddress);
        l2XERC20Gateway.setMessengerAddress(l2TwineMessengerAddress);

        l2ETHGateway.setRoleManagerAddress(roleManagerAddress);
        l2ETHGateway.setRouterAddress(l2GatewayRouterAddress);
        l2ETHGateway.setMessengerAddress(l2TwineMessengerAddress);
        uint256[] memory ethGatewaychainId = new uint256[](1);
        address[] memory ethCounterpartGateWay = new address[](1);
        ethGatewaychainId[0] = chainIdOne;
        ethCounterpartGateWay[0] = l1EthGatewayAddress;
        l2ETHGateway.setCounterpartGateway(
            ethGatewaychainId,
            ethCounterpartGateWay
        );


        // Stop broadcasting transactions
        vm.stopBroadcast();

        console.log("All Values are Set");

    }
}
