// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface ISP1Helios {
    function latestExecutionBlockNumber() external view returns (uint256);
    function executionStateRoots(uint256) external view returns (bytes32);
}
