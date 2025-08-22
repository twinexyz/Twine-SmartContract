// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

// The recommended ERC20 implementation for bridge token.
// deployed in L2 when original token is on L1
interface ITwineERC20 is IERC20 {

     /*************
     * Events    *
     *************/
    
    /// @notice Emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 amount, address indexed minter);
    
    /// @notice Emitted when tokens are burned
    event TokensBurned(address indexed from, uint256 amount, address indexed burner);

    /**
     * @notice Mints tokens to a specified address
     * @param _to The address to mint tokens to
     * @param _amount The amount of tokens to mint
     * @dev Only addresses with MINTER_ROLE can call this function
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Burns tokens from a specified address
     * @param _from The address to burn tokens from
     * @param _amount The amount of tokens to burn
     * @dev Only addresses with BURNER_ROLE can call this function
     * @dev The _from address must have sufficient balance
     */
    function burn(address _from, uint256 _amount) external;
}
