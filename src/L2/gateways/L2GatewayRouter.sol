// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IL2ETHGateway} from "./interfaces/IL2ETHGateway.sol";
import {IL2ERC20Gateway} from "./interfaces/IL2ERC20Gateway.sol";
import {IL2GatewayRouter} from "./interfaces/IL2GatewayRouter.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";

/// @title L2GatewayRouter
/// @notice The `L2GatewayRouter` is the main entry for withdrawing Ether and ERC20 tokens.
/// All deposited tokens are routed to corresponding gateways.
/// @dev One can also use this contract to query L1/L2 token address mapping.
/// In the future, ERC-721 and ERC-1155 tokens will be added to the router too.
contract L2GatewayRouter is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    IL2GatewayRouter
{
    using TypeConversionLib for address;
    /*************
     * Variables *
     *************/
    /// @notice The address of L2ETHGateway.
    address public ethGateway;

    /// @notice The addess of default L2 ERC20 gateway, normally the L2StandardERC20Gateway contract.
    address public defaultERC20Gateway;

    /// @notice Mapping from L2 ERC20 token address to corresponding L2ERC20Gateway.
    // solhint-disable-next-line var-name-mixedcase
    mapping(address => address) public ERC20Gateway;

    address public roleManager;

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

    function initialize(
        address _ethGateway,
        address _defaultERC20Gateway,
        address _roleManagerAddress
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
        roleManager = _roleManagerAddress;
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL2ERC20Gateway
    function getL1ERC20Address(
        uint256 chainId,
        address l2Address
    ) external view returns (string memory) {
        address gateway = getERC20Gateway(l2Address);
        if (gateway == address(0)) {
            return address(0).addressToString();
        }

        return IL2ERC20Gateway(gateway).getL1ERC20Address(chainId, l2Address);
    }

    /// @notice Return the corresponding gateway address for given token address.
    /// @param token The address of token to query.
    function getERC20Gateway(address token) public view returns (address) {
        address gateway = ERC20Gateway[token];
        if (gateway == address(0)) {
            gateway = defaultERC20Gateway;
        }
        return gateway;
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable {
        withdrawERC20AndCall(
            token,
            to,
            amount,
            chainId,
            gasLimit,
            new bytes(0)
        );
    }

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20AndCall(
        address token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes memory data
    ) public payable nonReentrant {
        address gateway = getERC20Gateway(token);
        require(gateway != address(0), "no gateway available");

        // encode msg.sender with data
        bytes memory routerData = abi.encode(_msgSender(), data);

        IL2ERC20Gateway(gateway).withdrawERC20AndCall{value: msg.value}(
            token,
            to,
            amount,
            chainId,
            gasLimit,
            routerData
        );
    }

    /// @inheritdoc IL2ETHGateway
    function withdrawETH(
        address l2Token,
        string memory l1Token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit
    ) external payable override {
        withdrawETHAndCall(
            l2Token,
            l1Token,
            to,
            amount,
            chainId,
            gasLimit,
            new bytes(0)
        );
    }

    /// @inheritdoc IL2ETHGateway
    function withdrawETHAndCall(
        address l2Token,
        string memory l1Token,
        string memory to,
        uint256 amount,
        uint256 chainId,
        uint256 gasLimit,
        bytes memory data
    ) public payable override {
        address gateway = ethGateway;
        require(gateway != address(0), "eth gateway available");

        // encode msg.sender with data
        bytes memory routerData = abi.encode(_msgSender(), data);

        IL2ETHGateway(gateway).withdrawETHAndCall{value: msg.value}(
            l2Token,
            l1Token,
            to,
            amount,
            chainId,
            gasLimit,
            routerData
        );
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @inheritdoc IL2GatewayRouter
    function setETHGateway(
        address newEthGateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        address oldEthGateway = ethGateway;
        ethGateway = newEthGateway;

        emit SetETHGateway(oldEthGateway, newEthGateway);
    }

    /// @inheritdoc IL2GatewayRouter
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

    /// @inheritdoc IL2GatewayRouter
    function setERC20Gateway(
        address[] memory tokens,
        address[] memory gateways
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(tokens.length == gateways.length, "length mismatch");
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            address oldGateway = ERC20Gateway[tokens[i]];
            ERC20Gateway[tokens[i]] = gateways[i];

            emit SetERC20Gateway(tokens[i], oldGateway, gateways[i]);
        }
    }

    function setRoleManagerAddress(
        address roleManagerAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(roleManagerAddress != address(0), "value cann't be zero");
        roleManager = roleManagerAddress;
    }

    function updateTokenMapping(
        uint256,
        address,
        string memory
    ) external virtual {
        revert("Not accessible from router contract");
    }
}
