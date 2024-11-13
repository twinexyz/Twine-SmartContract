// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Types {
    /**
     * @Notice List of ALL Struct being used to Encode and Decode RLP Messages
     */

    // Enum representing transaction types
    enum TxType {
        Legacy, // Legacy transaction pre EIP-2929
        Eip2930, // AccessList transaction
        Eip1559, // Transaction with Priority fee
        Eip4844, // Shard Blob Transactions - EIP-4844
        Eip7702, // EOA Contract Code Transactions - EIP-7702
        Deposit // Optimism Deposit transaction (conditional)
    }

    // Represents log data with indexed topics and plain data
    struct LogData {
        address logAddress;
        bytes32[] topics; // The indexed topic list (using bytes32 for B256)
        bytes data; // The plain data (using bytes for variable-length binary data)
    }

    // Represents the main receipt body
    struct ReceiptObject {
        TxType txType; // Receipt type (using enum TxType)
        bool success; // If transaction is executed successfully
        uint64 cumulativeGasUsed; // Gas used
        bytes bloom;
        LogData[] logs; // Logs sent from contracts (array of Log structs)
    }

    struct AccessList {
        address _address;
        bytes32[] storageKeys;
    }

    struct RLPTransactionObject {
        uint256 chainId;
        uint256 nonce;
        uint256 maxPriorityFeePerGas;
        uint256 maxFeePerGas;
        uint256 gas;
        address to;
        uint256 value;
        bytes input;
        AccessList[] accesslist;
        bool v;
        bytes32 r;
        bytes32 s;
    }
}
