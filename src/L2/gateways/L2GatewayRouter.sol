// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IL2GatewayRouter} from "./interfaces/IL2GatewayRouter.sol";
import {IL2ETHGateway} from "./interfaces/IL2ETHGateway.sol";
import {IL2ERC20Gateway} from "./interfaces/IL2ERC20Gateway.sol";

/// @title L2GatewayRouter
/// @notice The `L2GatewayRouter` is the main entry for withdrawing Ether and ERC20 tokens.
/// All deposited tokens are routed to corresponding gateways.
/// @dev One can also use this contract to query L1/L2 token address mapping.
/// In the future, ERC-721 and ERC-1155 tokens will be added to the router too.
contract L2GatewayRouter is ContextUpgradeable, IL2GatewayRouter {
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

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _ethGateway, address _defaultERC20Gateway) external initializer {
        // OwnableUpgradeable.__Ownable_init();

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
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL2ERC20Gateway
    function getL2ERC20Address(address) external pure returns (address) {
        revert("unsupported");
    }

    /// @inheritdoc IL2ERC20Gateway
    function getL1ERC20Address(address _l2Address) external view returns (address) {
        address _gateway = getERC20Gateway(_l2Address);
        if (_gateway == address(0)) {
            return address(0);
        }

        return IL2ERC20Gateway(_gateway).getL1ERC20Address(_l2Address);
    }

    /// @notice Return the corresponding gateway address for given token address.
    /// @param _token The address of token to query.
    function getERC20Gateway(address _token) public view returns (address) {
        address _gateway = ERC20Gateway[_token];
        if (_gateway == address(0)) {
            _gateway = defaultERC20Gateway;
        }
        return _gateway;
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable  {
        withdrawERC20AndCall(_token, _to, _amount, new bytes(0), _gasLimit);
    }

    /// @inheritdoc IL2ERC20Gateway
    function withdrawERC20AndCall(
        address _token,
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) public payable  {
        address _gateway = getERC20Gateway(_token);
        require(_gateway != address(0), "no gateway available");

        // encode msg.sender with _data
        bytes memory _routerData = abi.encode(_msgSender(), _data);

        IL2ERC20Gateway(_gateway).withdrawERC20AndCall{value: msg.value}(_token, _to, _amount, _routerData, _gasLimit);
    }

    function withdrawETH(uint256 _amount, uint256 _gasLimit) external payable  {
        address _gateway = ethGateway;
        require(_gateway != address(0), "eth gateway available");
        IL2ETHGateway(_gateway).withdrawETH{value: msg.value}(_msgSender(), _amount, _gasLimit);

    }

    /// @inheritdoc IL2ETHGateway
    function withdrawETH(
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable  {
        address _gateway = ethGateway;
        require(_gateway != address(0), "eth gateway available");
        IL2ETHGateway(_gateway).withdrawETH{value: msg.value}(_to, _amount, _gasLimit);
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @inheritdoc IL2GatewayRouter
    function setETHGateway(address _newEthGateway) external {
        address _oldEthGateway = ethGateway;
        ethGateway = _newEthGateway;

        emit SetETHGateway(_oldEthGateway, _newEthGateway);
    }

    /// @inheritdoc IL2GatewayRouter
    function setDefaultERC20Gateway(address _newDefaultERC20Gateway) external {
        address _oldDefaultERC20Gateway = defaultERC20Gateway;
        defaultERC20Gateway = _newDefaultERC20Gateway;

        emit SetDefaultERC20Gateway(_oldDefaultERC20Gateway, _newDefaultERC20Gateway);
    }

    /// @inheritdoc IL2GatewayRouter
    function setERC20Gateway(address[] memory _tokens, address[] memory _gateways) external  {
        require(_tokens.length == _gateways.length, "length mismatch");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address _oldGateway = ERC20Gateway[_tokens[i]];
            ERC20Gateway[_tokens[i]] = _gateways[i];

            emit SetERC20Gateway(_tokens[i], _oldGateway, _gateways[i]);
        }
    }
}
