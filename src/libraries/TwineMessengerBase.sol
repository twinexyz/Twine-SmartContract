// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
    address public immutable counterpart;

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

    constructor(address _counterpart) {
        if (_counterpart == address(0)) {
            revert ErrorZeroAddress();
        }

        counterpart = _counterpart;
    }

    function __TwineMessengerBase_init(address, address _feeVault) internal {
        if (_feeVault != address(0)) {
            feeVault = _feeVault;
        }
    }
    
}
