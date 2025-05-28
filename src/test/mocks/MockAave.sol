// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMockAave} from "./IMockAave.sol";

contract MockAave is IMockAave {
     uint256 public override totalDeposits;

    function deposit(
        address ,
        uint256 amount,
        address ,
        uint16 
    ) external {
        totalDeposits += amount;
    }
}
