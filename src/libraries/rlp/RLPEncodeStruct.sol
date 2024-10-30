// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma experimental ABIEncoderV2;

import "./RLPEncode.sol";
import "./Types.sol";

library RLPEncodeStruct {
    using RLPEncode for bytes;
    using RLPEncode for string;
    using RLPEncode for uint256;
    using RLPEncode for int256;
    using RLPEncode for address;
    using RLPEncode for bool;

    using RLPEncodeStruct for Types.Log;
    using RLPEncodeStruct for Types.LogData;
    using RLPEncodeStruct for Types.Receipt;
    using RLPEncodeStruct for Types.ReceiptObject;

    uint8 internal constant LIST_SHORT_START = 0xc0;
    uint8 internal constant LIST_LONG_START = 0xf7;

    function encodeLogData(Types.LogData memory _ld)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;

        for (uint256 i = 0; i < _ld.topics.length; i++) {
            temp = abi.encodePacked(_ld.topics[i]).encodeBytes();

            _rlp = abi.encodePacked(_rlp, temp);
        }

        _rlp = abi
            .encodePacked(addLength(_rlp.length, false), _rlp)
            .encodeBytes();
        _rlp = abi.encodePacked(_rlp, _ld.data.encodeBytes());
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeLog(Types.Log memory _l)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        _rlp = abi.encodePacked(
            _l.logAddress.encodeAddress(),
            _l.logData.encodeLogData().encodeBytes()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeReceipt(Types.Receipt memory _r)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;

        for (uint256 i = 0; i < _r.logs.length; i++) {
            temp = _r.logs[i].encodeLog();
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi
            .encodePacked(addLength(_rlp.length, false), _rlp)
            .encodeBytes();

        _rlp = abi.encodePacked(abi.encodePacked(_r.txType).encodeBytes(),_r.success.encodeBool(),uint256(_r.cumulativeGasUsed).encodeUint(),_rlp);
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
        

    }

    function encodeReceiptObject(Types.ReceiptObject memory _ro)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        _rlp = abi.encodePacked(
            _ro.bloom.encodeBytes(),
            _ro.receipt.encodeReceipt().encodeBytes()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    //  Adding LIST_HEAD_START by length
    //  There are two cases:
    //  1. List contains less than or equal 55 elements (total payload of the RLP) -> LIST_HEAD_START = LIST_SHORT_START + [0-55] = [0xC0 - 0xF7]
    //  2. List contains more than 55 elements:
    //  - Total Payload = 512 elements = 0x0200
    //  - Length of Total Payload = 2
    //  => LIST_HEAD_START = \x (LIST_LONG_START + length of Total Payload) \x (Total Payload) = \x(F7 + 2) \x(0200) = \xF9 \x0200 = 0xF90200
    function addLength(uint256 length, bool isLongList)
        internal
        pure
        returns (bytes memory)
    {
        if (length > 55 && !isLongList) {
            bytes memory payLoadSize = RLPEncode.encodeUintByLength(length);
            return
                abi.encodePacked(
                    addLength(payLoadSize.length, true),
                    payLoadSize
                );
        } else if (length <= 55 && !isLongList) {
            return abi.encodePacked(uint8(LIST_SHORT_START + length));
        }
        return abi.encodePacked(uint8(LIST_LONG_START + length));
    }
}
