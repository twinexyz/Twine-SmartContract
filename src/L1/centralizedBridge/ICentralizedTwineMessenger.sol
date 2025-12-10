// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITwineL1MessengerBase} from "../../libraries/messenger/ITwineL1MessengerBase.sol";
import { TwineTypes } from "../../libraries/types/TwineTypes.sol";

interface ICentralizedTwineMessenger is ITwineL1MessengerBase {
    
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
    /// @param twineAddress The address in Twine.
    /// @param amount The amount of token to send.

    event MessageTransaction(
        TwineTypes.TransactionType txnType,
        uint64 nonce,
        uint64 chainId,
        uint64 blockNumber,
        address l1Token,
        address l2Token,
        address l1Address,
        address twineAddress,
        uint256 amount,
        bytes message
    );

    event L2WithdrawExecuted(
        uint64 nonce,
        string indexed l1Token,
        string l2Token,
        string indexed receiver,
        string indexed amount,
        uint256 blockNumber
    );

    /// @notice Emitted when the chain ID is updated
    /// @param oldChainId The previous chain ID value
    /// @param newChainId The new chain ID
    event ChainIdUpdated(uint64 indexed oldChainId, uint64 indexed newChainId);

    /*****************
     * Custom Errors *
     *****************/
    /// @notice Thrown when withdrawal is already processed
    error WithdrawalAlreadyProcessed();

    /// @notice Thrown when an invalid chain ID is provided
    error InvalidChainId();

    /************
     * Structs  *
     ************/
    struct L2WithdrawValues {
        uint64 batchNumber;
        uint64 nonce;
        bytes32 batchHash;
        string to;
        string l1Token;
        string l2Token;
        string amount;
    }


    /*************************
     * Public View Functions *
     *************************/
    /// @return Message index The index of the messages
    function messageIndex() external view returns (uint64);

    /*****************************
     * Public Mutating Functions *
     *****************************/
    /// @notice Sets the chain id
    /// @param _chainId chain id to set
    function setChainId(uint64 _chainId) external;

    /// @notice sets the gateway addresses
    /// @param _ethGateway the adress of ETH gateway
    /// @param _ERC20Gateway the adress of CustomERC20 gateway
    function setGatewayAddress(address _ethGateway, address _ERC20Gateway) external;

    /// @notice Executes withdraws initiated from L2
    /// @param withdrawParams encoded struct with withdraw details
    function executeL2Withdraw(
        bytes calldata withdrawParams
    ) external;
}