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
     //count for the messages
    uint256 public messageCount;

    /// @notice The address of fee vault, collecting cross domain messaging fee.
    address public feeVault;

    address public roleManager;

    //chainId=> L1TwineMessenger
    mapping(uint256 => address) public counterpartMessenger;

    //chainId=> (l2Token => L2Gateway)
    mapping(uint256 => mapping(address => address)) public tokenGateWay;

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
        require(_roleManagerAddress != address(0), "value cann't be zero");
        roleManager = _roleManagerAddress;
    }

    /// @notice sets the fee vault address
    function setFeeVault(
        address _feeVault
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_feeVault != address(0), "Address can't be zero");
        feeVault = _feeVault;
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
        uint256 len = _chainId.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                _counterpartMessenger[i] != address(0),
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

    function setTokenGateWay(
        uint256 chainId,
        address l2Token,
        address gateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        tokenGateWay[chainId][l2Token] = gateway;
    }

    /// @dev The storage slots for future usage.
    uint256[49] private __gap;
}
