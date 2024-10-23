// SPDX-License-Identifier: MIT

pragma solidity =0.8.24;

import {IL2ERC20Gateway, L2ERC20Gateway} from "./L2ERC20Gateway.sol";
import {IL2TwineMessenger} from "../IL2TwineMessenger.sol";
import {IL1ERC20Gateway} from "../../L1/gateways/interfaces/IL1ERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";
import {ITwineERC20} from "../../libraries/token/ITwineERC20.sol";

/// @title L2CustomERC20Gateway
/// @notice The `L2CustomERC20Gateway` is used to withdraw custom ERC20 compatible tokens on layer 2 and
/// finalize deposit the tokens from layer 1.
/// @dev The withdrawn tokens will be burned directly. On finalizing deposit, the corresponding
/// tokens will be minted and transferred to the recipient.
contract L2CustomERC20Gateway is L2ERC20Gateway {
    /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for ERC20 token is updated.
    /// @param l2Token The address of corresponding ERC20 token in layer 2.
    /// @param oldL1Token The address of the old corresponding ERC20 token in layer 1.
    /// @param newL1Token The address of the new corresponding ERC20 token in layer 1.
    event UpdateTokenMapping(address indexed l2Token, address indexed oldL1Token, address indexed newL1Token);

    /*************
     * Variables *
     *************/

    /// @notice Mapping from layer 2 token address to layer 1 token address for ERC20 token.
    // solhint-disable-next-line var-name-mixedcase
    mapping(address => address) public tokenMapping;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of `L2CustomERC20Gateway`.
    ///
    /// @dev The parameters `_counterpart`, `_router` and `_messenger` are no longer used.
    ///
    /// @param _counterpart The address of `L1CustomERC20Gateway` contract in L1.
    /// @param _router The address of `L2GatewayRouter` contract in L2.
    /// @param _messenger The address of `L2TwineMessenger` contract in L2.
    function initialize(
        address _counterpart,
        address _router,
        address _messenger
    ) external initializer {
        TwineGatewayBase._initialize(_counterpart, _router, _messenger);
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc IL2ERC20Gateway
    function getL1ERC20Address(address _l2Token) external view override returns (address) {
        return tokenMapping[_l2Token];
    }

    /// @inheritdoc IL2ERC20Gateway
    function getL2ERC20Address(address) public pure override returns (address) {
        revert("unimplemented");
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL2ERC20Gateway
    function finalizeDepositERC20(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual override  nonReentrant {
        require(msg.value == 0, "nonzero msg.value");
        require(_l1Token != address(0), "token address cannot be 0");
        require(_l1Token == tokenMapping[_l2Token], "l1 token mismatch");

        ITwineERC20(_l2Token).mint(_to, _amount);

        _doCallback(_to, _data);

        emit FinalizeDepositERC20(_l1Token, _l2Token, _from, _to, _amount, _data);
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 2 to layer 1 token mapping.
    ///
    /// @dev To make the token mapping consistent with L1, this should be called from L1.
    ///
    /// @param _l2Token The address of corresponding ERC20 token on layer 2.
    /// @param _l1Token The address of ERC20 token on layer 1.
    function updateTokenMapping(address _l2Token, address _l1Token) external onlyRoles(IRoleManager(roleManagerAddress).CHAIN_ADMIN()) {
        address _oldL1Token = tokenMapping[_l2Token];
        tokenMapping[_l2Token] = _l1Token;

        emit UpdateTokenMapping(_l2Token, _oldL1Token, _l1Token);
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @inheritdoc L2ERC20Gateway
    function _withdraw(
        address _token,
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) internal virtual override nonReentrant {
        address _l1Token = tokenMapping[_token];
        require(_l1Token != address(0), "no corresponding l1 token");

        require(_amount > 0, "withdraw zero amount");

        // 1. Extract real sender if this call is from L2GatewayRouter.
        address _from = _msgSender();
        if (router == _from) {
            (_from, _data) = abi.decode(_data, (address, bytes));
        }

        // 2. Burn token.
        ITwineERC20(_token).burn(_from, _amount);

        // 3. Generate message passed to L1CustomERC20Gateway.
        bytes memory _message = abi.encodeCall(
            IL1ERC20Gateway.finalizeWithdrawERC20,
            (_l1Token, _token, _from, _to, _amount, _data)
        );

        // 4. send message to L2TwineMessenger
        IL2TwineMessenger(messenger).sendMessage{value: msg.value}(counterpart, 0, _message, _gasLimit);

        emit WithdrawERC20(_l1Token, _token, _from, _to, _amount, _data);
    }
}
