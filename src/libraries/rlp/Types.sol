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

    // Represents a log entry
    struct Log {
        address logAddress; // The address which emitted this log
        LogData logData; // The log data (using bytes for generic data)
    }

    // Represents log data with indexed topics and plain data
    struct LogData {
        bytes32[] topics; // The indexed topic list (using bytes32 for B256)
        bytes data; // The plain data (using bytes for variable-length binary data)
    }

    // Represents the main receipt body
    struct Receipt {
        TxType txType; // Receipt type (using enum TxType)
        bool success; // If transaction is executed successfully
        uint64 cumulativeGasUsed; // Gas used
        Log[] logs; // Logs sent from contracts (array of Log structs)
    }

    // Represents a receipt with a Bloom filter using bytes
    struct ReceiptObject {
        bytes bloom; // Bloom filter built from logs (now using bytes)
        Receipt receipt; // Main receipt body
    }
}
