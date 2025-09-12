// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL1ERC20} from "./IL1ERC20.sol";
import {IRoleManager} from "../access/IRoleManager.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title TwineStandardERC20
 * @dev Upgradeable ERC20 token
 */
contract L1ERC20 is IL1ERC20, ERC20Upgradeable {
    /*************
     * Variables *
     *************/

    /// @notice Number of decimal places for the token
    uint8 public decimals_;

    /// @notice Address of the role manager contract
    IRoleManager public roleManager;

    /***********
     * Errors  *
     ***********/
    /// @notice Thrown when an invalid input for token name and symbol is given
    error InvalidTokenInitialization();

    /// @notice Thrown when a zero address is provided where not allowed
    error ZeroAddress();

    /// @notice Thrown when a zero amount is provided where not allowed
    error ZeroAmount();

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * @notice Restricts function access to addresses with specific roles
     * @param role The role hash required to call the function
     */
    modifier onlyRole(bytes32 role) {
        roleManager.checkRole(role, msg.sender);
        _;
    }

    /**
     * @notice Validates that an address is not zero
     * @param addr The address to validate
     */
    modifier notZeroAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    /**
     * @notice Validates that an amount is greater than zero
     * @param amount The amount to validate
     */
    modifier notZeroAmount(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // Disable initializers in the implementation contract
        _disableInitializers();
    }

    /***********************
     * Initialize Function *
     ***********************/

    /**
     * @notice Initializes the contract with token details
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _decimals Number of decimal places for the token
     * @param _roleManager Address of the role manager contract
     * @dev This function can only be called once due to the initializer modifier
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _roleManager
    ) external initializer {
        // Validate inputs
        if (bytes(_name).length == 0 || bytes(_symbol).length == 0) {
            revert InvalidTokenInitialization(); // Reusing error for empty strings
        }
        if (_roleManager == address(0)) revert ZeroAddress();
        decimals_ = _decimals;
        roleManager = IRoleManager(_roleManager);
        __ERC20_init(_name, _symbol);
    }

    /**********************
     * External Functions *
     **********************/
    function mint(
        address _to,
        uint256 _amount
    )
        external
        notZeroAddress(_to)
        notZeroAmount(_amount)
        onlyRole(roleManager.CHAIN_ADMIN())
    {
        _mint(_to, _amount);
        emit TokensMinted(_to, _amount, _msgSender());
    }

    function burn(
        uint256 _amount
    )
        external
        notZeroAmount(_amount)
        onlyRole(roleManager.TWINE_TOKENS_BURNER())
    {
        _burn(msg.sender, _amount);
        emit TokensBurned(msg.sender, _amount, _msgSender());
    }
}
