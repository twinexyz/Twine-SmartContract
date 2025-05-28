// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";

interface IL2MsgExecutor  {

    event TransactionCallFailed(uint256 index);
    function processMessage(IL2TwineMessenger.ContractCall[] memory messages) external; 

}