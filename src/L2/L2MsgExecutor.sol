// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IL2MsgExecutor} from "./IL2MsgExecutor.sol";
import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";


contract L2MsgExecutor is IL2MsgExecutor, ContextUpgradeable,ReentrancyGuardUpgradeable {
    address roleManager;
    error MessageExecutionFailed(uint256 messageIndex);
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

    function initialize(address roleManagerAddress) external initializer {
        roleManager = roleManagerAddress;
    }

    function processMessage(
        IL2TwineMessenger.L1ForcedTxn[] memory messages
    ) external override
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()){
        for (uint256 i = 0; i < messages.length; i++) {
            IL2TwineMessenger.L1ForcedTxn memory callMessage = messages[i];
            (bool success, ) = callMessage.targetContract.call{
                value: callMessage.value
            }(callMessage.data);
            if (!success) {
                emit TransactionCallFailed(i);
                revert MessageExecutionFailed(i);
            }
        }
    }
}
