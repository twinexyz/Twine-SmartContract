// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

// The recommended ERC20 implementation for bridge token.
// deployed in L2 when original token is on L1
// deployed in L1 when original token is on L2
interface ITwineERC20 is IERC20 {

    /// @notice Mint some token to recipient's account.
    /// @dev Gateway Utilities, only gateway contract can call
    /// @param _to The address of recipient.
    /// @param _amount The amount of token to mint.
    function mint(address _to, uint256 _amount) external;

    /// @notice Mint some token from account.
    /// @dev Gateway Utilities, only gateway contract can call
    /// @param _from The address of account to burn token.
    /// @param _amount The amount of token to mint.
    function burn(address _from, uint256 _amount) external;
}
