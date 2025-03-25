// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IL1ETHGateway} from "./interfaces/IL1ETHGateway.sol";
import {IL1ERC20Gateway} from "./interfaces/IL1ERC20Gateway.sol";
import {IL1GatewayRouter} from "./interfaces/IL1GatewayRouter.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";

/// @title L1GatewayRouter
/// @notice The `L1GatewayRouter` is the main entry for depositing Ether and ERC20 tokens.
/// All deposited tokens are routed to corresponding gateways.
contract L1GatewayRouter is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    IL1GatewayRouter,
    IL1ETHGateway,
    IL1ERC20Gateway
{
    using SafeERC20 for IERC20;
    /// @notice The address of L1ETHGateway.
    address public ethGateway;

    /// @notice The addess of default ERC20 gateway, normally the L1StandardERC20Gateway contract.
    address public defaultERC20Gateway;

    /// @notice Mapping from ERC20 token address to corresponding L1ERC20Gateway.
    // solhint-disable-next-line var-name-mixedcase
    mapping(address => address) public ERC20Gateway;

    /// @notice The address of gateway in current execution context.
    address public gatewayInContext;

    /// @notice The address of RoleManagerContract
    address public roleManager;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    modifier onlyNotInContext() {
        require(gatewayInContext == address(0), "Only not in context");
        _;
    }

    modifier onlyInContext() {
        require(_msgSender() == gatewayInContext, "Only in deposit context");
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1GatewayRouter.
    /// @param _ethGateway The address of L1ETHGateway contract.
    /// @param _defaultERC20Gateway The address of default ERC20 Gateway contract.
    function initialize(
        address _ethGateway,
        address _defaultERC20Gateway,
        address _roleManager
    ) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        // it can be zero during initialization
        if (_defaultERC20Gateway != address(0)) {
            defaultERC20Gateway = _defaultERC20Gateway;
            emit SetDefaultERC20Gateway(address(0), _defaultERC20Gateway);
        }

        // it can be zero during initialization
        if (_ethGateway != address(0)) {
            ethGateway = _ethGateway;
            emit SetETHGateway(address(0), _ethGateway);
        }

        roleManager = _roleManager;
    }

    /// @inheritdoc IL1ERC20Gateway
    function getL2ERC20Address(
        address l1Address
    ) external view returns (address) {
        address gateway = getERC20Gateway(l1Address);
        if (gateway == address(0)) {
            return address(0);
        }

        return IL1ERC20Gateway(gateway).getL2ERC20Address(l1Address);
    }

    /// @inheritdoc IL1GatewayRouter
    function getERC20Gateway(address token) public view returns (address) {
        address gateway = ERC20Gateway[token];
        if (gateway == address(0)) {
            gateway = defaultERC20Gateway;
        }
        return gateway;
    }

    /// @inheritdoc IL1GatewayRouter
    /// @dev All the gateways should have reentrancy guard to prevent potential attack though this function.
    function requestERC20(
        address sender,
        address token,
        uint256 amount
    ) external onlyInContext returns (uint256) {
        address caller = _msgSender();
        uint256 balance = IERC20(token).balanceOf(caller);
        IERC20(token).safeTransferFrom(sender, caller, amount);
        amount = IERC20(token).balanceOf(caller) - balance;
        return amount;
    }

    /// @inheritdoc IL1ERC20Gateway
    function depositERC20(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable override {
        depositERC20AndCall(token, to, amount, gasLimit, new bytes(0));
    }

    /// @inheritdoc IL1ERC20Gateway
    function depositERC20AndCall(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) public payable override onlyNotInContext {
        address gateway = getERC20Gateway(token);
        require(gateway != address(0), "no gateway available");

        // enter deposit context
        gatewayInContext = gateway;

        // encode msg.sender with data
        bytes memory routerData = abi.encode(_msgSender(), data);

        IL1ERC20Gateway(gateway).depositERC20AndCall{value: msg.value}(
            token,
            to,
            amount,
            gasLimit,
            routerData
        );

        // leave deposit context
        gatewayInContext = address(0);
    }

    function finalizeTokenWithdrawal(
        string memory,
        string memory,
        string memory,
        string memory,
        uint64 
    ) external payable virtual override(IL1ERC20Gateway, IL1ETHGateway) {
        revert("Not accessible from router contract");
    }

    /// @inheritdoc IL1ERC20Gateway
    function forcedWithdrawalERC20(
        address l1Token,
        address l2Token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable virtual override {
        address gateway = getERC20Gateway(l1Token);
        require(gateway != address(0), "no gateway available");
        bytes memory routerData = abi.encode(_msgSender(), data);
        IL1ERC20Gateway(gateway).forcedWithdrawalERC20(
            l1Token,
            l2Token,
            to,
            amount,
            gasLimit,
            routerData
        );
    }

    /// @inheritdoc IL1ETHGateway
    function depositETH(
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable override {
        depositETHAndCall(to, amount, gasLimit, new bytes(0));
    }

    /// @inheritdoc IL1ETHGateway
    function depositETHAndCall(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) public payable override onlyNotInContext {
        address gateway = ethGateway;
        require(gateway != address(0), "eth gateway available");

        // encode msg.sender with data
        bytes memory routerData = abi.encode(_msgSender(), data);

        IL1ETHGateway(gateway).depositETHAndCall{value: msg.value}(
            to,
            amount,
            gasLimit,
            routerData
        );
    }

    /// @inheritdoc IL1ETHGateway
    function forcedWithdrawalETH(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable virtual override {
        address gateway = ethGateway;
        require(gateway != address(0), "eth gateway available");
        bytes memory routerData = abi.encode(_msgSender(), data);
        IL1ETHGateway(gateway).forcedWithdrawalETH(
            to,
            amount,
            gasLimit,
            routerData
        );
    }

    function setRoleManagerAddress(address roleManagerAddress) external {
        require(roleManagerAddress != address(0), "value cann't be zero");
        roleManager = roleManagerAddress;
    }

    function setETHGateway(
        address newEthGateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        address oldETHGateway = ethGateway;
        ethGateway = newEthGateway;

        emit SetETHGateway(oldETHGateway, newEthGateway);
    }

    /// @inheritdoc IL1GatewayRouter
    function setDefaultERC20Gateway(
        address newDefaultERC20Gateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        address oldDefaultERC20Gateway = defaultERC20Gateway;
        defaultERC20Gateway = newDefaultERC20Gateway;

        emit SetDefaultERC20Gateway(
            oldDefaultERC20Gateway,
            newDefaultERC20Gateway
        );
    }

    /// @inheritdoc IL1GatewayRouter
    function setERC20Gateway(
        address[] memory tokens,
        address[] memory gateways
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(tokens.length == gateways.length, "length mismatch");
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            require(tokens[i] != address(0), " Value cann't be zero");
            require(gateways[i] != address(0), " Value cann't be zero");
            address oldGateway = ERC20Gateway[tokens[i]];
            ERC20Gateway[tokens[i]] = gateways[i];
            emit SetERC20Gateway(tokens[i], oldGateway, gateways[i]);
        }
    }
}
