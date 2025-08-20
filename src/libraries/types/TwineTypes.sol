// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface TwineTypes {
    /***********
     * Enums   *
     ***********/
    /// @notice Transaction type in L1
    /// @param Deposit the deposit transaction type
    /// @param Withdraw the forced withdrawal transaction type
    /// @param Message the normal message type
    enum TransactionType {
        Deposit,
        Withdraw,
        Message
    }

    /************
     * Structs  *
     ************/
    /// @notice Deposit message stored data
    /// @param nonce the nonce of the message
    /// @param toAddress the Twine address to deposit into
    /// @param l1Token the address of token to deposit on l1
    /// @param l2Token the address of token to receive on l2
    /// @param chainId chain id of the l1 where deposit is initiated
    /// @param amount amount of token to deposit
    /// @param blockNumber block number on which deposit occured
    struct MessageData {
        TransactionType txnType;
        uint64 nonce;
        uint64 chainId;
        uint64 blockNumber;
        string fromAddress;
        string toAddress;
        string l1Token;
        string l2Token;
        string amount;
        bytes message;
    }
}
