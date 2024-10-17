// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ITwineGateway} from "./ITwineGateway.sol";
import {ITwineMessenger} from "../ITwineMessenger.sol";
import {ITwineGatewayCallback} from "../callbacks/ITwineGatewayCallback.sol";


/// @title TwineGatewayBase
/// @notice The `TwineGatewayBase` is a base contract for gateway contracts used in both in L1 and L2.
abstract contract TwineGatewayBase is ReentrancyGuardUpgradeable, ITwineGateway {

    /*************
     * Constants *
     *************/

    /// @inheritdoc ITwineGateway
    address public immutable override counterpart;

    /// @inheritdoc ITwineGateway
    address public immutable override router;

    /// @inheritdoc ITwineGateway
    address public immutable override messenger;

    /// @dev The storage slots for future usage.
    uint256[46] private __gap;

    /***************
     * Constructor *
     ***************/

    constructor(
        address _counterpart,
        address _router,
        address _messenger
    ) {
        if (_counterpart == address(0) || _messenger == address(0) || _router == address(0)) {
            revert ErrorZeroAddress();
        }

        counterpart = _counterpart;
        router = _router;
        messenger = _messenger;
    }

    function _initialize(
        address,
        address,
        address
    ) internal {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
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