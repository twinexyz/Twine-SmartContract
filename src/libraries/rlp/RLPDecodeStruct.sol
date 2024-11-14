// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma experimental ABIEncoderV2;

import "./Types.sol";
import "./RLPEncode.sol";
import "lib/Solidity-RLP/contracts/RLPReader.sol";

library RLPDecodeStruct {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;

    function decodeReceiptObject(bytes memory rlpEncodedReceipt)
        public
        pure
        returns (Types.ReceiptWithoutTxType memory receipt)
    {
        // Convert the bytes to an RLPItem
        RLPReader.RLPItem memory item = rlpEncodedReceipt.toRlpItem();

        // Ensure that the item is a list
        require(item.isList(), "Invalid receipt format");

        // Decode the list items
        RLPReader.Iterator memory iter = item.iterator();

        uint256 flag;

        // Assuming the order of elements in the list is known:
        flag = (iter.next().toUint()); // Decode txType
        if (flag == 1) {
            receipt.success = true;
        } else {
            receipt.success = false;
        }

        receipt.cumulativeGasUsed = uint64(iter.next().toUint()); // Decode cumulativeGasUsed

        receipt.bloom = iter.next().toBytes(); // Decode bloom

        // Decode logs
        if (iter.hasNext()) {
            RLPReader.RLPItem[] memory logsItems = iter.next().toList(); // Get logs as a list of items
            receipt.logs = new Types.LogData[](logsItems.length);

            for (uint256 i = 0; i < logsItems.length; i++) {
                RLPReader.RLPItem memory logItem = logsItems[i];

                //Check if logItem is a list before proceeding
                require(logItem.isList(), "Log item is not a list");

                RLPReader.Iterator memory logIter = logItem.iterator();
                Types.LogData memory logData;

                logData.logAddress = logIter.next().toAddress(); // Decode log address

                // Decode topics (assuming they are provided as a list)
                if (logIter.hasNext()) {
                    RLPReader.RLPItem[] memory topicsItems = logIter
                        .next()
                        .toList();
                    logData.topics = new bytes32[](topicsItems.length);

                    for (uint256 j = 0; j < topicsItems.length; j++) {
                        logData.topics[j] = bytes32(topicsItems[j].toUint()); // Convert each topic to bytes32
                    }
                }

                if (logIter.hasNext()) {
                    logData.data = logIter.next().toBytes(); // Decode data only if available
                } else {
                    logData.data = ""; // Default to empty if no data present
                }

                receipt.logs[i] = logData; // Assign decoded log data to receipt logs
            }
        }

        return receipt; // Return the decoded ReceiptObject
    }
}
