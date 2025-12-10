// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TwineTypes} from "../../libraries/types/TwineTypes.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {ICentralizedTwineMessenger} from "./ICentralizedTwineMessenger.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";
import {TwineChainDecoder} from "../../libraries/decoders/TwineChainDecoder.sol";
import {TwineL1MessengerBase} from "../../libraries/messenger/TwineL1MessengerBase.sol";
import {ICentralizedETHGateway} from "./centralizedGateways/interfaces/ICentralizedETHGateway.sol";
import {ITwineL1MessengerBase} from "../../libraries/messenger/ITwineL1MessengerBase.sol";
import {ICentralizedERC20Gateway} from "./centralizedGateways/interfaces/ICentralizedERC20Gateway.sol";

contract CentralizedTwineMessenger is TwineL1MessengerBase, ICentralizedTwineMessenger {
    using TypeConversionLib for string;

    /*************
     * Variables *
     *************/ 
    // gateway address of eth
    address public ethGateway;

    // gateway address of erc20 gateway
    address public ERC20Gateway;

    // chainId where of chain where this bridge is deployed
    uint64 chainId;

    // nonce of the last sent message
    uint64 public override messageIndex;

    /*************
     * Mappings  *
     *************/
    /// @notice Mapping of executed withdraw hash to a boolean value
    mapping(bytes32 => bool) public isL2WithdrawExecuted;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of CentralizedTwineMessenger.
    /// @param _counterpart The address of L2TwineMessenger in L2.
    function initialize(
        address _counterpart,
        address _roleManager
    ) external initializer {
        __TwineMessengerBase_init(_counterpart, _roleManager);
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/
    /// @inheritdoc ICentralizedTwineMessenger
    function setGatewayAddress(
        address _ethGateway,
        address _ERC20Gateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_ethGateway == address(0) || _ERC20Gateway == address(0)) {
            revert ErrorZeroAddress();
        }
        ethGateway = _ethGateway;
        ERC20Gateway = _ERC20Gateway;
    }

    /// @inheritdoc ICentralizedTwineMessenger
    function setChainId(
        uint64 _chainId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_chainId == 0) revert InvalidChainId();
        uint64 oldChainId = chainId;
        chainId = _chainId;
        emit ChainIdUpdated(oldChainId, _chainId);
    }

    /// @inheritdoc ITwineL1MessengerBase
    function sendMessage(
        TransactionType txnType,
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    )
        external
        payable
        override
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_GATEWAYS())
    {
        _sendMessage(txnType, from, to, l1Token, l2Token, amount, message);
    }

    /// @inheritdoc ICentralizedTwineMessenger
    function executeL2Withdraw(
        bytes calldata withdrawParams
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()){
        if (isL2WithdrawExecuted[keccak256(withdrawParams)])
            revert WithdrawalAlreadyProcessed();

        L2WithdrawValues memory withdrawValues = TwineChainDecoder
            .decodeL2WithdrawValuesForCentralizedBridge(withdrawParams);

        executeTokenWithdrawal(
            withdrawValues.nonce,
            withdrawValues.l1Token,
            withdrawValues.l2Token,
            withdrawValues.to,
            withdrawValues.amount
        );
        isL2WithdrawExecuted[keccak256(withdrawParams)] = true;
        emit L2WithdrawExecuted(
            withdrawValues.nonce,
            withdrawValues.l1Token,
            withdrawValues.l2Token,
            withdrawValues.to,
            withdrawValues.amount,
            block.number
        );

    }

     /**********************
     * Internal Functions *
     **********************/
    function _sendMessage(
        TransactionType txnType,
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) internal { 
        unchecked {
            ++messageIndex;
        }

        emit MessageTransaction(
            TwineTypes.TransactionType.Deposit,
            messageIndex,
            chainId,
            uint64(block.number),
            l1Token,
            l2Token,
            from,
            to,
            amount,
            message
        );
    }

     function executeTokenWithdrawal(
        uint64 nonce,
        string memory l1Token,
        string memory l2Token,
        string memory receiver,
        string memory amount
    ) internal {
        if (l1Token.stringToAddress() == address(0)) {
            ICentralizedETHGateway(ethGateway).finalizeTokenWithdrawal(
                l1Token,
                l2Token,
                receiver,
                amount,
                nonce
            );
        } else {
            // ERC20 withdrawal
            ICentralizedERC20Gateway(ERC20Gateway).finalizeTokenWithdrawal(
                l1Token,
                l2Token,
                receiver,
                amount,
                nonce
            );
        }
    }

}

