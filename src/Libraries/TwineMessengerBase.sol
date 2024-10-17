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

    /// @dev Internal function to generate the correct cross domain calldata for a message.
    /// @param _sender Message sender address.
    /// @param _target Target contract address.
    /// @param _value The amount of ETH pass to the target.
    /// @param _messageNonce Nonce for the provided message.
    /// @param _message Message to send to the target.
    /// @return ABI encoded cross domain calldata.
    function _encodeXDomainCalldata(
        address _sender,
        address _target,
        uint256 _value,
        uint256 _messageNonce,
        bytes memory _message
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(address,address,uint256,uint256,bytes)",
                _sender,
                _target,
                _value,
                _messageNonce,
                _message
            );
    }
}
