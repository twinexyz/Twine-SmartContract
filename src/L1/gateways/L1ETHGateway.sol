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
        if (msg.value < (gasLimit + amount)) revert InsufficientGasValue();
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
        if (amountUint == 0) revert ZeroAmount();

        address l2TokenAddr = l2Token.stringToAddress();
        if (l2TokenAddr != l2TokenAddress) revert WrongL2Token();

        if (address(this).balance < amountUint)
            revert InsufficientContractBalance();

        address toAddr = to.stringToAddress();
        (bool success, ) = toAddr.call{value: amountUint}("");
        if (!success) revert ETHTransferFailed();

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
        if (_l2TokenAddress == address(0)) revert ZeroAddress();
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
        if (amount == 0) revert ZeroAmount();
        if ( amount + gasLimit < msg.value) revert LessThanMessageValue();

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
        if (amount == 0) revert ZeroAmount();
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
