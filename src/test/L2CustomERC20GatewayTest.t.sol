// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {MockERC20} from "./mocks/MockERC20.sol";
import {L2GatewayRouter} from "../L2/gateways/L2GatewayRouter.sol";
import {L2TwineMessenger} from "../L2/L2TwineMessenger.sol";
import {RoleManager} from "../libraries/access/RoleManager.sol";
import {IL1ERC20Gateway, L1CustomERC20Gateway} from "../L1/gateways/L1CustomERC20Gateway.sol";
import {IL2ERC20Gateway, L2CustomERC20Gateway} from "../L2/gateways/L2CustomERC20Gateway.sol";

contract L2CustomERC20GatewayTest is Test {
    L2CustomERC20Gateway private gateway;
    L2GatewayRouter private router;
    L1CustomERC20Gateway private counterpartGateway;
    RoleManager private roleManager;
    MockERC20 l1Token;
    MockERC20 l2Token;
    address initialOwner = 0x19B78FF82C94b5E517f2279f3fBF10498B039179;
    L2TwineMessenger internal l2Messenger;
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    address L2CustomERC20GatewayAddress;

    function setUp() public {
        vm.startPrank(initialOwner);
        // Deploy tokens
        l1Token = new MockERC20("Mock L2", "ML2");
        l2Token = new MockERC20("Mock L2", "ML2");

          address roleManagerAddress = Upgrades.deployTransparentProxy(
            "RoleManager.sol",
            msg.sender,
            abi.encodeCall(RoleManager.initialize, (initialOwner))
        );
        roleManager = RoleManager(roleManagerAddress);

        roleManager.grantRole(CHAIN_ADMIN, initialOwner);
        roleManager.checkRole(CHAIN_ADMIN, initialOwner);

         address L2GatewayRouterAddress = Upgrades.deployTransparentProxy(
            "L2GatewayRouter.sol",
            msg.sender,
            abi.encodeCall(L2GatewayRouter.initialize, (address(0), address(0),address(roleManager)))
        );
        router = L2GatewayRouter(L2GatewayRouterAddress);

        // Deploying an upgradeable proxy for L2TwineMessenger
        address L2TwineMessengerAddress = Upgrades.deployTransparentProxy(
            "L2TwineMessenger.sol",
            msg.sender,
            abi.encodeCall(
                L2TwineMessenger.initialize,
                (0,address(0), address(0))
            )
        );

        l2Messenger = L2TwineMessenger(L2TwineMessengerAddress);

        vm.startPrank(initialOwner);
        l2Token.mint(initialOwner, 100000);

        //setup customErc20 Gateway
        L2CustomERC20GatewayAddress = Upgrades.deployTransparentProxy(
            "L2CustomERC20Gateway.sol",
            msg.sender,
            abi.encodeCall(
                L2CustomERC20Gateway.initialize,
                (address(0), address(router), address(l2Messenger))
            )
        );
        gateway = L2CustomERC20Gateway(L2CustomERC20GatewayAddress);

        //setup the rolemanager

        address[] memory tokens = new address[](1);
        address[] memory gateways = new address[](1);

        tokens[0] = address(l2Token);
        gateways[0] = address(gateway);
        // setup gateway in router;
        vm.startPrank(initialOwner);
        router.setERC20Gateway(tokens, gateways);
        router.setETHGateway(address(gateway));
        router.setDefaultERC20Gateway(address(gateway));
        gateway.setRoleManagerAddress(address(roleManager));
        vm.stopPrank();
    }
        function testwithdrawERC20() public {
            vm.startPrank(initialOwner);
            gateway.updateTokenMapping(1,address(l2Token), address(l1Token));
            assertEq(l2Token.balanceOf(initialOwner),100000);
            l2Token.approve(address(gateway), 100000);
            l2Token.approve(address(router), 100000);
            assertEq(l1Token.balanceOf(initialOwner),0);
            router.withdrawERC20(
                address(l2Token),
                initialOwner,
                10,
                1,
                0
            );
            gateway.withdrawERC20(
                address(l2Token),
                initialOwner,
                10,
                1,
                0
            );
            assertEq(l2Token.balanceOf(initialOwner),99980);
        }
}