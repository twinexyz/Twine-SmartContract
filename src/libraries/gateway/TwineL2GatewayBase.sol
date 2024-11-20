// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ITwineL2Gateway} from "./ITwineL2Gateway.sol";
import {IRoleManager} from "../access/IRoleManager.sol";
import {ITwineGatewayCallback} from "../callbacks/ITwineGatewayCallback.sol";

/// @title TwineGatewayBase
/// @notice The `TwineGatewayBase` is a base contract for gateway contracts used in both in L1 and L2.
abstract contract TwineL2GatewayBase is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ITwineL2Gateway
{
    /*************
     * Constants *
     *************/

    /// need to remove this variable as it is not used anymore
    /// @inheritdoc ITwineL2Gateway
    address public override counterpart;

    /// @inheritdoc ITwineL2Gateway
    address public override router;

    /// @inheritdoc ITwineL2Gateway
    address public override messenger;

    address public roleManager;
    
    //chainId=> L1Gateway
    mapping(uint256=>mapping(address => address)) public override counterpartGateWay;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    function _initialize(
        address _counterpart,
        address _router,
        address _messenger,
        address _roleManager
    ) internal {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        counterpart = _counterpart;
        router = _router;
        messenger = _messenger;
        roleManager = _roleManager;
    }

    function setRoleManagerAddress(address _roleManagerAddress)
        external 
    {
        roleManager = _roleManagerAddress;
    }

    function setRouterAddress(address _router)
        external
        onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN())
    {
        router = _router;
    }


    function setMessengerAddress(address _messenger)
        external
        onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN())
    {
        messenger = _messenger;
    }

    function setCounterpartGateway(uint256[] memory _chainId,address[]memory _l1TokenAddress,address[] memory _counterpartGateWay) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_chainId.length == _counterpartGateWay.length && _chainId.length == _l1TokenAddress.length, "length mismatch");
        for (uint256 i = 0; i < _chainId.length; i++) {
            require(_l1TokenAddress[i] != address(0)," Value cann't be zero");
            require(_counterpartGateWay[i] != address(0)," Value cann't be zero");
            address _oldCounterPart = counterpartGateWay[_chainId[i]][_l1TokenAddress[i]];
            counterpartGateWay[_chainId[i]][_l1TokenAddress[i]] = _counterpartGateWay[i];
            emit SetCounterpartGateway(_chainId[i], _oldCounterPart, _counterpartGateWay[i]);
        }
    }


    /// @dev The storage slots for future usage.
    uint256[46] private __gap;
}
