// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IMockAave {
    function totalDeposits() external view returns (uint256);
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}
