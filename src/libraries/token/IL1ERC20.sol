// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// The recommended ERC20 implementation for L1 token.
// deployed in L1
interface IL1ERC20 is IERC20 {

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
     * @dev Only addresses with CHAIN_ADMIN role can call this function
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Burns tokens from a specified address
     * @param _amount The amount of tokens to burn
     * @dev Only addresses who owns the token can call this function
     * @dev The msg.sender address must have sufficient balance
     */
    function burn(uint256 _amount) external;
}
