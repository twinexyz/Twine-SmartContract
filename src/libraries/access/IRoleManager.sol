// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

interface IRoleManager {
    /**
     * @notice Sets new adminRole for a role
     * This function can be called by the account having adminRole for the `role`
     * @param role - particular role
     * @param adminRole - new role to be assigned as admin
     **/
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Checks role for an account
     * Reverts if the account doesnt have permission of the role
     * @param role - role of contract.
     * @param account - address of user.
     **/
    function checkRole(bytes32 role, address account) external view;

    /**
     * @notice Returns bytes32 value of the public variable DEFAULT_ADMIN_ROLE
     **/
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns bytes32 value of the public variable ACTIONS_ADMIN
     **/
    function CHAIN_ADMIN() external view returns (bytes32);

}