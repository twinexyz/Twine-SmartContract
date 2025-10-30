// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title RoleManager
 * @notice RoleManager is used to grant roles .
 **/
contract RoleManager is ContextUpgradeable, AccessControlUpgradeable {
    bytes32 public constant CHAIN_ADMIN = keccak256("CHAIN_ADMIN");
    bytes32 public constant TWINE_CHAIN = keccak256("TWINE_CHAIN");
    bytes32 public constant TWINE_GATEWAYS = keccak256("TWINE_GATEWAYS");
    bytes32 public constant TWINE_MESSENGER = keccak256("TWINE_MESSENGER");
    bytes32 public constant LZ_MESSAGE_LIBRARY = keccak256("LZ_MESSAGE_LIBRARY");
    bytes32 public constant TWINE_TOKENS_MINTER =
        keccak256("TWINE_TOKENS_MINTER");
    bytes32 public constant TWINE_TOKENS_BURNER =
        keccak256("TWINE_TOKENS_burner");
    bytes32 public constant TWINE_OPERATIONS_HANDLER =
        keccak256("TWINE_OPERATIONS_HANDLER");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        __AccessControl_init();
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /**
     * @notice Sets new adminRole for a role
     * This function can be called by the account having adminRole for the `role`
     * @param role - particular role
     * @param adminRole - new role to be assigned as admin
     **/
    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) public onlyRole(getRoleAdmin(role)) {
        _setRoleAdmin(role, adminRole);
    }

    /**
     * @notice Checks role for an account
     * Reverts if the account doesnt have permission of the role
     * @param role - role of contract.
     * @param account - address of user.
     **/
    function checkRole(bytes32 role, address account) public view {
        _checkRole(role, account);
    }
}
