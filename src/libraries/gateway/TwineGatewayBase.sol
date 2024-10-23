// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ITwineGateway} from "./ITwineGateway.sol";
import {ITwineMessenger} from "../ITwineMessenger.sol";
import {IRoleManager} from "../access/IRoleManager.sol";
import {ITwineGatewayCallback} from "../callbacks/ITwineGatewayCallback.sol";

/// @title TwineGatewayBase
/// @notice The `TwineGatewayBase` is a base contract for gateway contracts used in both in L1 and L2.
abstract contract TwineGatewayBase is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ITwineGateway
{
    /*************
     * Constants *
     *************/

    /// @inheritdoc ITwineGateway
    address public override counterpart;

    /// @inheritdoc ITwineGateway
    address public override router;

    /// @inheritdoc ITwineGateway
    address public override messenger;

    address public roleManagerAddress;

    /// @dev The storage slots for future usage.
    uint256[46] private __gap;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManagerAddress).checkRole(role, _msgSender());
        _;
    }

    function _initialize(
        address _counterpart,
        address _router,
        address _messenger
    ) internal {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        counterpart = _counterpart;
        router = _router;
        messenger = _messenger;
    }

    function setRoleManagerAddress(address _roleManagerAddress)
        external
    {
        roleManagerAddress = _roleManagerAddress;
    }

    function setAddress(address _counterpart, address _router, address _messenger)
        external
        onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN())
    {
        counterpart = _counterpart;
        router = _router;
        messenger = _messenger;
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @dev Internal function to forward calldata to target contract.
    /// @param _to The address of contract to call.
    /// @param _data The calldata passed to the contract.
    function _doCallback(address _to, bytes memory _data) internal {
        if (_data.length > 0 && _to.code.length > 0) {
            ITwineGatewayCallback(_to).onTwineGatewayCallback(_data);
        }
    }
}
