// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IRoleManager} from "../access/IRoleManager.sol";
import {ITwineL2MessengerBase} from "./ITwineL2MessengerBase.sol";

abstract contract TwineL2MessengerBase is
    ContextUpgradeable,
    ITwineL2MessengerBase,
    ReentrancyGuardUpgradeable
{
    /*************
     * Variables *
     *************/

    /// @notice The address of fee vault, collecting cross domain messaging fee.
    address public feeVault;

    address public roleManager;

    //chainId=> L1TwineMessenger
    mapping(uint256 => address) counterpartMessenger;

    //chainId=> L1Gateway
    mapping(uint256 => mapping(string => string))
        public tokenCounterpartGateWay;

    //count for the messages
    uint256 public messageCount;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __TwineMessengerBase_init(
        uint256 _chainId,
        address _counterpartMessenger,
        address _roleManagerAddress
    ) internal {
        __Context_init();
        __ReentrancyGuard_init();
        counterpartMessenger[_chainId] = _counterpartMessenger;
        roleManager = _roleManagerAddress;
    }

    /// @notice sets the rolemanager contract address
    function setRoleManager(
        address _roleManagerAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        roleManager = _roleManagerAddress;
    }

    /// @notice sets the fee vault address
    function setFeeVault(
        address _freeVault
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        feeVault = _freeVault;
    }

    /// @notice sets the counter part messenger
    function setCounterpartMessenger(
        uint256[] memory _chainId,
        address[] memory _counterpartMessenger
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(
            _chainId.length == _counterpartMessenger.length,
            "length mismatch"
        );
        for (uint256 i = 0; i < _chainId.length; i++) {
            require(
                _chainId[i] != 0 && _counterpartMessenger[i] != address(0),
                " Value cann't be zero"
            );
            address _oldCounterPart = counterpartMessenger[_chainId[i]];
            counterpartMessenger[_chainId[i]] = _counterpartMessenger[i];
            emit SetCounterpartMessenger(
                _chainId[i],
                _oldCounterPart,
                _counterpartMessenger[i]
            );
        }
    }

    /// @dev The storage slots for future usage.
    uint256[49] private __gap;
}
