// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {ICentralizedETHGateway} from "./interfaces/ICentralizedETHGateway.sol";
import {ICentralizedERC20Gateway} from "./interfaces/ICentralizedERC20Gateway.sol";
import {ICentralizedGatewayRouter} from "./interfaces/ICentralizedGatewayRouter.sol";
import {IRoleManager} from "../../../libraries/access/IRoleManager.sol";

/// @title CentralizedGatewayRouter
/// @notice The `CentralizedGatewayRouter` is the main entry for depositing Ether and ERC20 tokens.
/// All deposited tokens are routed to corresponding gateways.
contract CentralizedGatewayRouter is 
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ICentralizedGatewayRouter,
    ICentralizedETHGateway,
    ICentralizedERC20Gateway
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

    /// @notice Initialize the storage of CentralizedGatewayRouter.
    /// @param _ethGateway The address of CentralizedETHGateway contract.
    /// @param _defaultERC20Gateway The address of default ERC20 Gateway contract.
    function initialize(
        address _ethGateway,
        address _defaultERC20Gateway,
        address _roleManager
    ) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        // Cache for gas optimization
        address zero = address(0);

        if (_defaultERC20Gateway != zero) {
            defaultERC20Gateway = _defaultERC20Gateway;
            emit SetDefaultERC20Gateway(zero, _defaultERC20Gateway);
        }

        if (_ethGateway != zero) {
            ethGateway = _ethGateway;
            emit SetETHGateway(zero, _ethGateway);
        }

        roleManager = _roleManager;
    }

      /// @inheritdoc ICentralizedERC20Gateway
    function getL2ERC20Address(
        address l1Address
    ) external view returns (address) {
        address gateway = getERC20Gateway(l1Address);
        return
            gateway == address(0)
                ? address(0)
                : ICentralizedERC20Gateway(gateway).getL2ERC20Address(l1Address);
    }

    /// @inheritdoc ICentralizedGatewayRouter
    function getERC20Gateway(
        address token
    ) public view returns (address gateway) {
        gateway = ERC20Gateway[token];
        if (gateway == address(0)) {
            gateway = defaultERC20Gateway;
        }
    }

    /// @inheritdoc ICentralizedGatewayRouter
    /// @dev All the gateways should have reentrancy guard to prevent potential attack though this function.
    function requestERC20(
        address sender,
        address token,
        uint256 amount
    ) external onlyInContext returns (uint256) {
        address caller = _msgSender();
        IERC20 tokenContract = IERC20(token);
        uint256 balanceBefore = tokenContract.balanceOf(caller);
        tokenContract.safeTransferFrom(sender, caller, amount);

        unchecked {
            return tokenContract.balanceOf(caller) - balanceBefore;
        }
    }

    /// @inheritdoc ICentralizedERC20Gateway
    function depositERC20(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable override {
        depositERC20AndCall(token, to, amount, gasLimit, new bytes(0));
    }

     /// @inheritdoc ICentralizedERC20Gateway
    function depositERC20AndCall(
        address token,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) public payable override onlyNotInContext {
        address gateway = getERC20Gateway(token);
        if (gateway == address(0)) revert NoGatewayAvailable();

        // enter deposit context
        gatewayInContext = gateway;

        // encode msg.sender with data
        bytes memory routerData = abi.encode(_msgSender(), data);

        ICentralizedERC20Gateway(gateway).depositERC20AndCall{value: msg.value}(
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
    ) external payable virtual override(ICentralizedERC20Gateway, ICentralizedETHGateway) {
        revert NotAccessibleFromRouter();
    }

    /// @inheritdoc ICentralizedETHGateway
    function depositETH(
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable override {
        address gateway = ethGateway;
        depositETHAndCall(to, amount, gasLimit, new bytes(0));
    }

    /// @inheritdoc ICentralizedETHGateway
    function depositETHAndCall(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) public payable override onlyNotInContext {
        address gateway = ethGateway;
        if (gateway == address(0)) revert NoETHGatewayAvailable();

        // encode msg.sender with data
        bytes memory routerData = abi.encode(_msgSender(), data);

        ICentralizedETHGateway(gateway).depositETHAndCall{value: msg.value}(
            to,
            amount,
            gasLimit,
            routerData
        );
    }

    function setRoleManagerAddress(address roleManagerAddress) external {
        if (roleManagerAddress == address(0)) revert ZeroAddress();
        roleManager = roleManagerAddress;
    }

    function setETHGateway(
        address newEthGateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (newEthGateway == address(0)) revert ZeroAddress();
        address oldETHGateway = ethGateway;
        ethGateway = newEthGateway;

        emit SetETHGateway(oldETHGateway, newEthGateway);
    }

    /// @inheritdoc ICentralizedGatewayRouter
    function setDefaultERC20Gateway(
        address newDefaultERC20Gateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (newDefaultERC20Gateway == address(0)) revert ZeroAddress();
        address oldDefaultERC20Gateway = defaultERC20Gateway;
        defaultERC20Gateway = newDefaultERC20Gateway;

        emit SetDefaultERC20Gateway(
            oldDefaultERC20Gateway,
            newDefaultERC20Gateway
        );
    }

    /// @inheritdoc ICentralizedGatewayRouter
    function setERC20Gateway(
        address[] memory tokens,
        address[] memory gateways
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (tokens.length != gateways.length) revert LengthMismatch();
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            if (tokens[i] == address(0) || gateways[i] == address(0)) {
                revert ZeroAddress();
            }
            address oldGateway = ERC20Gateway[tokens[i]];
            ERC20Gateway[tokens[i]] = gateways[i];
            emit SetERC20Gateway(tokens[i], oldGateway, gateways[i]);
        }
    }
}