// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ITwineL1Gateway} from "./ITwineL1Gateway.sol";
import {IRoleManager} from "../access/IRoleManager.sol";

/// @title TwineGatewayBase
/// @notice The `TwineGatewayBase` is a base contract for gateway contracts used in both in L1 and L2.
abstract contract TwineL1GatewayBase is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ITwineL1Gateway
{
    /*************
     * Constants *
     *************/

    ///@notice chain Id of the contract deployed
    uint64 public chainId;

    /// @inheritdoc ITwineL1Gateway
    address public override gatewayRouter;

    /// @inheritdoc ITwineL1Gateway
    address public override messenger;

    ///@notice address of roleManagerContract
    address public roleManager;

    /// @dev The storage slots for future usage.
    uint256[45] private __gap;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    function _initialize(
        address _gatewayRouter,
        address _messenger,
        address _roleManager,
        uint64 _chainId
    ) internal {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        gatewayRouter = _gatewayRouter;
        messenger = _messenger;
        roleManager = _roleManager;
        chainId = _chainId;
    }

    /// @notice sets the rolemanager contract address
    function setRoleManagerAddress(
        address _roleManagerAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_roleManagerAddress != address(0),"value cann't be zero");
        roleManager = _roleManagerAddress;
    }

    /// @notice sets the gateway router address
    function setGatewayRouter(
        address _gatewayRouter
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_gatewayRouter != address(0),"value cann't be zero");
        gatewayRouter = _gatewayRouter;
    }

    /// @notice sets the twine messenger contract address
    function setTwineMessenger(
        address _messenger
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_messenger != address(0),"value cann't be zero");
        messenger = _messenger;
    }

    /// @notice sets the chainId
     function setChainId(
        uint64 _chainId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        chainId = _chainId;
    }
}
