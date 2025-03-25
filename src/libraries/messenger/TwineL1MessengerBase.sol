// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IRoleManager} from "../access/IRoleManager.sol";
import {ITwineL1MessengerBase} from "./ITwineL1MessengerBase.sol";

abstract contract TwineL1MessengerBase is
    ContextUpgradeable,
    ITwineL1MessengerBase,
    ReentrancyGuardUpgradeable
{
    /*************
     * Constants *
     *************/

    /// @notice The address of counterpart TwineMessenger contract in L1/L2.
    address public counterpart;

    /*************
     * Variables *
     *************/

    /// @notice See {ITwineMessenger-xDomainMessageSender}
    address public override xDomainMessageSender;

    /// @notice The address of fee vault, collecting cross domain messaging fee.
    address public feeVault;

    address public roleManager;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __TwineMessengerBase_init(
        address _counterpart,
        address _roleManagerAddress
    ) internal {
        __Context_init();
        __ReentrancyGuard_init();
        counterpart = _counterpart;
        roleManager = _roleManagerAddress;
    }

    /// @notice sets the l2 counterpart messenger contract
    function setCounterpartMessenger(address _counterpart) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_counterpart != address(0)," Address cann't be zero");
        counterpart = _counterpart;
    }
    /// @notice sets the feevault  address
    function setFeeVault(
        address _feeVault
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_feeVault != address(0),"value cann't be zero");
        feeVault = _feeVault;
    }

    /// @notice sets the rolemanager contract address
    function setRoleManager(address _roleManagerAddress) external {
        require(_roleManagerAddress != address(0),"value cann't be zero");
        roleManager = _roleManagerAddress;
    }

    /// @dev The storage slots for future usage.
    uint256[50] private __gap;
}
