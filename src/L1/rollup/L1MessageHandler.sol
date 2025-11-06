// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IL1MessageHandler} from "./IL1MessageHandler.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {TwineTypes} from "../../libraries/types/TwineTypes.sol";
import {MessageHasherLib} from "../../libraries/utils/MessageHasherLib.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";
import {L1OApp} from "../../layerzero/L1Oapp.sol";

contract L1MessageHandler is ContextUpgradeable, IL1MessageHandler {
    using TypeConversionLib for string;
    using TypeConversionLib for address;

    /*************
     * Variables *
     *************/

    /// @notice The chai ID for the L1 where this contract is deployed
    uint64 chainId;

    /// @notice Twine's Endpoint ID
    uint32 twineEndpointId;

    /// @notice Latest message nonce
    uint64 public override messageIndex;

    /// @notice The address of L1TwineMessenger contract.
    address public messenger;

    /// @notice Address of the rolemanager contract
    address public roleManager;

    /// @notice Address of the Proxy contract
    address public messageHandlerProxy;

    /// @notice Address of L1 OApp
    address public l1OApp;

    /// @notice Flag to enable or disable layer zero route
    bool public layerZeroEnabled;


    /// @dev The storage slots reserved for future usage.
    uint256[46] private __gap;

    /*************
     * Mappings  *
     *************/
    
    /// @dev The mapping of messageNonce => messageRollingHash
    mapping(uint256 => bytes32) private messageRollingHashes;

    /**********************
     * Function Modifiers *
     **********************/
    modifier onlyMessenger() {
        if (_msgSender() != messenger) {
            revert OnlyMessenger();
        }
        _;
    }

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor external-library-linking
    constructor() {
        _disableInitializers();
    }

    // @notice Initialize the storage of L1MessageHandler.
    /// @param _chainId The chain id of L1.
    /// @param _messenger The address of L1TwineMessenger in L1.
    /// @param _roleManager The address of roleManager Contract.
    function initialize(
        uint64 _chainId,
        address _messenger,
        address _roleManager
    ) external initializer {
        messenger = _messenger;
        chainId = _chainId;
        roleManager = _roleManager;
    }

    /*************************
     * Public View Functions *
     *************************/
    /// @inheritdoc IL1MessageHandler
    function getMessageHash(
        uint256 messageNonce
    ) external view returns (bytes32) {
        if (messageIndex < messageNonce) {
            revert InvalidIndex();
        }
        return messageRollingHashes[messageNonce];
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IL1MessageHandler
    function setMessengerAddress(
        address _messenger
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_messenger == address(0)) {
            revert ErrorZeroAddress();
        }
        address oldMessenger = messenger;
        messenger = _messenger;
        emit MessengerAddressUpdated(oldMessenger, _messenger);
    }

    /// @inheritdoc IL1MessageHandler
    function setChainId(
        uint64 _chainId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_chainId == 0) revert InvalidChainId();
        uint64 oldChainId = chainId;
        chainId = _chainId;
        emit ChainIdUpdated(oldChainId, _chainId);
    }

    /// @inheritdoc IL1MessageHandler
    function setTwineEndpointId(
        uint32 _twineEndpointId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        twineEndpointId = _twineEndpointId;
    }

    /// @inheritdoc IL1MessageHandler
    function setRoleManager(
        address _roleManager
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_roleManager == address(0)) {
            revert ErrorZeroAddress();
        }
        address oldRoleManager = roleManager;
        roleManager = _roleManager;
        emit RoleManagerUpdated(oldRoleManager, _roleManager);
    }

    /// @inheritdoc IL1MessageHandler
    function setMessageHandlerProxy(
        address _proxyAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_proxyAddress == address(0)) {
            revert ErrorZeroAddress();
        }
        address oldProxy = messageHandlerProxy;
        messageHandlerProxy = _proxyAddress;
        emit MessageHandlerProxyUpdated(oldProxy, _proxyAddress);
    }

    /// @inheritdoc IL1MessageHandler
    function setOAppAddress(
        address _l1OAppAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_l1OAppAddress == address(0)) {
            revert ErrorZeroAddress();
        }
        address oldOApp = l1OApp;
        l1OApp = _l1OAppAddress;
        emit OAppUpdated(oldOApp, _l1OAppAddress);
    }

    /// @inheritdoc IL1MessageHandler
    function setLayerZeroStatus(
        bool _status
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        layerZeroEnabled = _status;
    }

    /// @inheritdoc IL1MessageHandler
    function appendCrossDomainDepositMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external override onlyMessenger {
        _handleDepositTransaction(from, to, l1Token, l2Token, amount, message);
    }

    /// @inheritdoc IL1MessageHandler
    function appendCrossDomainWithdrawalMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external override onlyMessenger {
        _handleWithdrawalTransaction(
            from,
            to,
            l1Token,
            l2Token,
            amount,
            message
        );
    }

    /**********************
     * Internal Functions *
     **********************/

    function _handleDepositTransaction(
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

        TwineTypes.MessageData memory depositMessageData = TwineTypes
            .MessageData({
                txnType: TwineTypes.TransactionType.Deposit,
                nonce: messageIndex,
                chainId: chainId,
                blockNumber: uint64(block.number),
                fromAddress: from.addressToString(),
                toAddress: to.addressToString(),
                l1Token: l1Token.addressToString(),
                l2Token: l2Token.addressToString(),
                amount: uintToString(amount),
                message: message
            });

        bytes32 particularTransactionHash = MessageHasherLib.hashL1Message(
            depositMessageData
        );

        messageRollingHashes[messageIndex] = particularTransactionHash;
        
        if (layerZeroEnabled) {
            bytes memory options = hex"0003010011010000000000000000000000000000c350";

            bytes memory payload = abi.encode(
                depositMessageData.txnType,
                depositMessageData.nonce,
                depositMessageData.chainId,
                depositMessageData.blockNumber,
                depositMessageData.fromAddress,
                depositMessageData.toAddress,
                depositMessageData.l1Token,
                depositMessageData.l2Token,
                depositMessageData.amount,
                depositMessageData.message
            );
            L1OApp(l1OApp).send(
                twineEndpointId,
                payload,
                options
            );
        }

        // emit deposit event
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

    function _handleWithdrawalTransaction(
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

        TwineTypes.MessageData memory withdrawMessageData = TwineTypes
            .MessageData({
                txnType: TwineTypes.TransactionType.Withdraw,
                nonce: messageIndex,
                chainId: chainId,
                blockNumber: uint64(block.number),
                fromAddress: from.addressToString(),
                toAddress: to.addressToString(),
                l1Token: l1Token.addressToString(),
                l2Token: l2Token.addressToString(),
                amount: uintToString(amount),
                message: message
            });


        bytes32 particularTransactionHash = computeTransactionHash(
            withdrawMessageData
        );

        messageRollingHashes[messageIndex] = particularTransactionHash;

        // emit event
        emit MessageTransaction(
            TwineTypes.TransactionType.Withdraw,
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

    function computeTransactionHash(
        TwineTypes.MessageData memory transactionData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    transactionData.txnType,
                    transactionData.nonce,
                    transactionData.chainId,
                    transactionData.blockNumber,
                    keccak256(transactionData.message),
                    transactionData.fromAddress,
                    transactionData.toAddress,
                    transactionData.l1Token,
                    transactionData.l2Token,
                    transactionData.amount
                )
            );
    }

    /// @notice Converts a uint256 to its string representation
    /// @param value The uint256 value to convert
    /// @return The string representation of the input value
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
