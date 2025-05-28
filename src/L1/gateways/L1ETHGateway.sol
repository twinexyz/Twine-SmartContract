// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL1TwineMessenger} from "../IL1TwineMessenger.sol";
import {IL1ETHGateway} from "./interfaces/IL1ETHGateway.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {IL2ERC20Gateway} from "../../L2/gateways/L2CustomERC20Gateway.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";
import {TwineL1GatewayBase} from "../../libraries/gateway/TwineL1GatewayBase.sol";
import {ITwineL1MessengerBase} from "../../libraries/messenger/ITwineL1MessengerBase.sol";

contract L1ETHGateway is TwineL1GatewayBase, IL1ETHGateway {
    using TypeConversionLib for string;
    using TypeConversionLib for address;

    address public l2TokenAddress;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1CustomERC20Gateway.
    /// @param _gatewayrouter The address of L1GatewayRouter in L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
    /// @param _roleManager The address of Role manager contract.
    function initialize(
        address _gatewayrouter,
        address _messenger,
        address _roleManager,
        uint64 _chainId
    ) external initializer {
        TwineL1GatewayBase._initialize(
            _gatewayrouter,
            _messenger,
            _roleManager,
            _chainId
        );
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL1ETHGateway
    function depositETH(
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external payable override {
         require(msg.value > 0, "Amount for gas is needed");
        require(
            msg.value >= (gasLimit + amount),
            "Not efficient gas value"
        );
        _deposit(to, amount, gasLimit, new bytes(0));
    }

    /// @inheritdoc IL1ETHGateway
    function depositETHAndCall(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable override {
        _deposit(to, amount, gasLimit, data);
    }

    /// @inheritdoc IL1ETHGateway
    function forcedWithdrawalETH(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) external payable override {
        _forcedWithdrawalEth(to, amount, gasLimit, data);
    }

    /// @inheritdoc IL1ETHGateway
    function finalizeTokenWithdrawal(
        string memory l1Token,
        string memory l2Token,
        string memory to,
        string memory amount,
        uint64 nonce
    )
        external
        payable
        override
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_CHAIN())
    {
        uint256 amountUint = amount.stringToUint();
        require(amountUint > 0, "Amount must be greater than zero");
        require(l2Token.stringToAddress() == l2TokenAddress, "Wrong L2Token");
        require(
            address(this).balance >= amountUint,
            "Insufficient contract balance"
        );
        (bool _success, ) = to.stringToAddress().call{value: amountUint}("");
        require(_success, "ETH transfer failed");

        emit FinalizeWithdrawETH(
            l1Token,
            l2Token,
            to,
            amount,
            nonce,
            chainId,
            block.number
        );
    }

    /// @notice Set the _l2TokenAddress
    function setL2TokenAddress(
        address _l2TokenAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_l2TokenAddress != address(0), "value cann't be zero");
        l2TokenAddress = _l2TokenAddress;
        emit L2TokenSET(l2TokenAddress);
    }

    /// @dev The internal ETH deposit implementation.
    /// @param to The address of recipient's account on L2.
    /// @param amount The amount of ETH to be deposited.
    /// @param gasLimit Gas limit required to complete the deposit on L2.
    /// @param data Additional call data to be passed
    function _deposit(
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) internal virtual {
        require(amount > 0, "Amount can not be zero");
        require(
            amount + gasLimit <= msg.value,
            "Amount and gas limit should not be greater than msg.value"
        );

        // Extract real sender if this call is from L1GatewayRouter.
        address from = _msgSender();

        if (gatewayRouter == from) {
            (from, data) = abi.decode(data, (address, bytes));
        }


        //Calculate the type of transaction
        ITwineL1MessengerBase.TransactionType transactionType = ITwineL1MessengerBase
                .TransactionType
                .deposit;

        IL1TwineMessenger(messenger).sendMessage{value: gasLimit}(
            transactionType,
            from,
            to,
            address(0),
            l2TokenAddress,
            amount,
            data
        );
    }

    /// @dev The internal ETH forced withdrawal implementation.
    /// @param to The address of recipient's account in L1.
    /// @param amount The amount of ETH to be withdrawn.
    /// @param data Additional call data to be passed
    function _forcedWithdrawalEth(
        address to,
        uint256 amount,
        uint256 /* gasLimit */,
        bytes memory data
    ) internal virtual {
        require(amount > 0, "withdrawing zero amount not allowed");
        // 1. Extract real sender if this call is from L1GatewayRouter
        address from = _msgSender();
        if (gatewayRouter == from) {
            (from, data) = abi.decode(data, (address, bytes));
        }
        // 3. Calculate the type of transaction
        ITwineL1MessengerBase.TransactionType transactionType = ITwineL1MessengerBase
                .TransactionType
                .withdrawal;

        IL1TwineMessenger(messenger).sendMessage{value: msg.value}(
            transactionType,
            from,
            to,
            address(0),
            l2TokenAddress,
            amount,
            data
        );
    }
}
