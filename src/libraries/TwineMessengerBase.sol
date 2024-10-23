// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ITwineMessenger} from "./ITwineMessenger.sol";

abstract contract TwineMessengerBase is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ITwineMessenger
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

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __TwineMessengerBase_init(address _counterpart) internal {
        __Context_init();
        __ReentrancyGuard_init();
        counterpart = _counterpart;
    }

    function setAddressMessengerBase(address _counterpart, address _feeVault)
        external
    {
        counterpart = _counterpart;
        feeVault = _feeVault;
    }
}
