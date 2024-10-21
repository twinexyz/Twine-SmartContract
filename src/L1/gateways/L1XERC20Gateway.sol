// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IXERC20} from "@xtoken/contracts/interfaces/IXERC20.sol";

import {IL2XERC20Gateway} from "../../L2/gateways/interfaces/IL2XERC20Gateway.sol";
import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL1XERC20Gateway} from "./interfaces/IL1XERC20Gateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineGatewayBase} from "../../libraries/gateway/TwineGatewayBase.sol";

contract L1XERC20Gateway is TwineGatewayBase,IL1XERC20Gateway {
     /**********
     * Events *
     **********/

    /// @notice Emitted when token mapping for XERC20 token is updated.
    /// @param l1Token The address of XERC20 token in layer 1.
    /// @param oldL2Token The address of the old corresponding XERC20 token in layer 2.
    /// @param newL2Token The address of the new corresponding XERC20 token in layer 2.
    event UpdateTokenMapping(address indexed l1Token, address indexed oldL2Token, address indexed newL2Token);

    /*************
     * Variables *
     *************/
    struct XTokenConfig {
        address l2Token;
        address l1xtokenAddress;
        address l2xtokenAddress;
        address l1LockboxAddress;
        address l2LockboxAddress;
    }
    /// @notice Mapping from l1 token address to l2 token address for XERC20 token.
    mapping(address => XTokenConfig) public tokenMapping;

    /***************
     * Constructor *
     ***************/

    /// @notice Constructor for `L1CustomERC20Gateway` implementation contract.
    ///
    /// @param _counterpart The address of `L2CustomERC20Gateway` contract in L2.
    /// @param _router The address of `L1GatewayRouter` contract in L1.
    /// @param _messenger The address of `L1TwineMessenger` contract L1.
    constructor(
        address _counterpart,
        address _router,
        address _messenger,
        address _roleManagerAddress
    ) TwineGatewayBase(_counterpart, _router, _messenger,_roleManagerAddress){
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1CustomERC20Gateway.
    ///
    /// @dev The parameters `_counterpart`, `_router` and `_messenger` are no longer used.
    ///
    /// @param _counterpart The address of L2CustomERC20Gateway in L2.
    /// @param _router The address of L1GatewayRouter in L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
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

    /// @inheritdoc IL1XERC20Gateway
    function getL2XERC20Address(address _l1Token) public view override returns (address) {
        return tokenMapping[_l1Token].l2Token;
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Update layer 1 to layer 2 token mapping.
    /// @param _l1Token The address of ERC20 token on layer 1.
    function updateTokenMapping(address _l1Token, XTokenConfig memory _newXTokenConfig) external payable {
        require(_newXTokenConfig.l2Token != address(0), "token address cannot be 0");

        XTokenConfig memory oldXTokenConfig = tokenMapping[_l1Token];
        address _oldL2Token = oldXTokenConfig.l2Token;
        tokenMapping[_l1Token] = _newXTokenConfig;

        emit UpdateTokenMapping(_l1Token, _oldL2Token, _newXTokenConfig.l2Token);

        // update corresponding mapping in L2, 1000000 gas limit should be enough
        bytes memory _message = abi.encodeCall(L1XERC20Gateway.updateTokenMapping, ( _l1Token,_newXTokenConfig));
        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(counterpart, 0, _message, 1000000, _msgSender());
    }

     /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL1XERC20Gateway
    function depositXERC20(
        address _token,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _deposit(_token, _msgSender(), _amount, new bytes(0), _gasLimit);
    }

    /// @inheritdoc IL1XERC20Gateway
    function depositXERC20(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) external payable override {
        _deposit(_token, _to, _amount, new bytes(0), _gasLimit);
    }

     /// @inheritdoc IL1XERC20Gateway
    function finalizeWithdrawXERC20(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual override nonReentrant {
        _beforeFinalizeWithdrawXERC20(_l1Token, _l2Token, _from, _to, _amount, _data);

        // @note can possible trigger reentrant call to this contract or messenger,
        // but it seems not a big problem.
        IXERC20(_l1Token).mint(_to, _amount);

        _doCallback(_to, _data);

        emit FinalizeWithdrawXERC20(_l1Token, _l2Token, _from, _to, _amount, _data);
    }


    /**********************
     * Internal Functions *
     **********************/

   
    function _beforeFinalizeWithdrawXERC20(
        address _l1Token,
        address _l2Token,
        address,
        address,
        uint256,
        bytes calldata
    ) internal {
        require(msg.value == 0, "nonzero msg.value");
        require(_l2Token != address(0), "token address cannot be 0");
        require(_l2Token == tokenMapping[_l1Token].l2Token, "l2 token mismatch");
    }

    /// @dev Internal function to do all the deposit operations.
    ///
    /// @param _token The token to deposit.
    /// @param _to The recipient address to recieve the token in L2.
    /// @param _amount The amount of token to deposit.
    /// @param _data Optional data to forward to recipient's account.
    /// @param _gasLimit Gas limit required to complete the deposit on L2.
    function _deposit(
        address _token,
        address _to,
        uint256 _amount,
        bytes memory _data,
        uint256 _gasLimit
    ) internal {
        address _l2Token = tokenMapping[_token].l2Token;
        require(_l2Token != address(0), "no corresponding l2 token");

        IXERC20(_token).burn(_to, _amount);
         bytes memory _message = abi.encodeCall(
            IL2XERC20Gateway.finalizeDepositXERC20,
            (_token, _l2Token, _msgSender(), _to, _amount, _data)
        );

        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(counterpart, 0, _message, _gasLimit, _msgSender());

        emit DepositXERC20(_token, _l2Token, _msgSender(), _to, _amount, _data);

    }


}