// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ITwineL1MessengerBase} from "./ITwineL1MessengerBase.sol";
import {IRoleManager} from "../access/IRoleManager.sol";

abstract contract TwineL1MessengerBase is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ITwineL1MessengerBase
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

    address public roleManagerAddress;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManagerAddress).checkRole(role, _msgSender());
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __TwineMessengerBase_init(address _counterpart,address _roleManagerAddress) internal {
        __Context_init();
        __ReentrancyGuard_init();
        counterpart = _counterpart;
        roleManagerAddress = _roleManagerAddress;
    }

    function setAddressMessengerBase(address _counterpart, address _feeVault)
        external onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN())
    {
        counterpart = _counterpart;
        feeVault = _feeVault;
    }

    function setRoleManager(address _roleManagerAddress) external onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN()){
        roleManagerAddress = _roleManagerAddress;
    }

    /// @dev The storage slots for future usage.
    uint256[50] private __gap;
}
