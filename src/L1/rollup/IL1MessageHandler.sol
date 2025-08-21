// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { TwineTypes } from "../../libraries/types/TwineTypes.sol";

interface IL1MessageHandler {
    /***********
     * Events  *
     ***********/
    /// @notice Emitted when a new L1 => L2  deposit transaction is appended to the queue.
    /// @param txnType The transaction type in L1.
    /// @param nonce The nonce of the message.
    /// @param chainId Chain Id of this L1.
    /// @param blockNumber The block number in which this transaction occured.
    /// @param l1Token Address of token to send from L1.
    /// @param l2Token address of token to receive on L2.
    /// @param l1Address The address in L1
    /// @param TwineAddress The address in Twine.
    /// @param amount The amount of token to send.

    event MessageTransaction(
        TwineTypes.TransactionType txnType,
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        address l1Token,
        address l2Token,
        address l1Address,
        address TwineAddress,
        uint256 amount,
        bytes message
    );

    /// @notice Emitted when the messenger address is updated
    /// @param oldMessenger The previous messenger address that was replaced
    /// @param newMessenger The new messenger address
    event MessengerAddressUpdated(
        address indexed oldMessenger,
        address indexed newMessenger
    );

    /// @notice Emitted when the chain ID is updated
    /// @param oldChainId The previous chain ID value
    /// @param newChainId The new chain ID
    event ChainIdUpdated(uint64 indexed oldChainId, uint64 indexed newChainId);

    /// @notice Emitted when the role manager contract address is updated
    /// @param oldRoleManager The previous role manager contract address
    /// @param newRoleManager The new role manager contract address
    event RoleManagerUpdated(
        address indexed oldRoleManager,
        address indexed newRoleManager
    );

    /// @notice Emitted when the message queue proxy address is updated by an admin
    /// @param oldProxy The previous message queue proxy address
    /// @param newProxy The new message queue proxy address
    event MessageHandlerProxyUpdated(
        address indexed oldProxy,
        address indexed newProxy
    );

     /*****************
     * Custom Errors *
     *****************/
    /// @notice Thrown when a function is called by an address other than the authorized messenger
    error OnlyMessenger();

    /// @notice Thrown when attempting to access a message with an invalid or non-existent index
    error InvalidIndex();

    /// @notice Thrown when an invalid chain ID is provided
    error InvalidChainId();

    /// @notice Thrown when a zero address (0x0) is provided
    error ErrorZeroAddress();

    /*************************
     * Public View Functions *
     *************************/
    /// @notice Returns the message hash.
    function getMessageHash(
        uint256 messageIndex
    ) external view returns (bytes32);

    /// @return Message index The index of the messages
    function messageIndex() external view returns (uint64);

    /*****************************
     * Public Mutating Functions *
     *****************************/
    /// @notice Sets the messenger address
    /// @param _messenger messenger address to set
    function setMessengerAddress(address _messenger) external;

    /// @notice Sets the chain id
    /// @param _chainId chain id to set
    function setChainId(uint64 _chainId) external;

    /// @notice sets role manager address
    /// @param _roleManager role manager address to set
    function setRoleManager(address _roleManager) external;

    /// @notice set the proxy Address of MessageHandler
    /// @param _proxyAddress message handler proxy address to set
    function setMessageHandlerProxy(address _proxyAddress) external;

    /// @notice Append new message to the deposit queue
    /// @param to Address of receiver on Twine
    /// @param l1Token address of token to deposit on L1
    /// @param l2Token address of token to be received on L2
    /// @param amount amount of token to deposit
    function appendCrossDomainDepositMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external;

    /// @notice Append new message to the deposit queue
    /// @param to Address of receiver on L1
    /// @param l1Token address of token to receive on L1
    /// @param l2Token address of token to be withdrawan from L2
    /// @param amount amount of token to withdraw
    function appendCrossDomainWithdrawalMessage(
        address from,
        address to,
        address l1Token,
        address l2Token,
        uint256 amount,
        bytes memory message
    ) external;
}
