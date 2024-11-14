// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
pragma experimental ABIEncoderV2;

import "./Types.sol";
import "./RLPEncode.sol";

library RLPEncodeStruct {
    using RLPEncode for bytes;
    using RLPEncode for string;
    using RLPEncode for uint256;
    using RLPEncode for int256;
    using RLPEncode for address;
    using RLPEncode for bool;

    using RLPEncodeStruct for Types.LogData;
    using RLPEncodeStruct for Types.AccessList;
    using RLPEncodeStruct for Types.ReceiptObject;
    using RLPEncodeStruct for Types.RLPTransactionObject;

    uint8 internal constant LIST_SHORT_START = 0xc0;
    uint8 internal constant LIST_LONG_START = 0xf7;

    function encodeLogData(
        Types.LogData memory _ld
    ) internal pure returns (bytes memory) {
        bytes memory _rlp;
        bytes memory temp;

        for (uint256 i = 0; i < _ld.topics.length; i++) {
            temp = abi.encodePacked(_ld.topics[i]).encodeBytes();

            _rlp = abi.encodePacked(_rlp, temp);
        }

        _rlp = abi.encodePacked(addLength(_rlp.length, false), _rlp);
        _rlp = abi.encodePacked(
            _ld.logAddress.encodeAddress(),
            _rlp,
            _ld.data.encodeBytes()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeReceiptObject(
        Types.ReceiptObject memory _ro
    ) internal pure returns (bytes memory) {
        bytes memory _rlp;
        bytes memory temp;

        for (uint256 i = 0; i < _ro.logs.length; i++) {
            temp = _ro.logs[i].encodeLogData();
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi.encodePacked(addLength(_rlp.length, false), _rlp);

        _rlp = abi.encodePacked(
            _ro.success.encodeBool(),
            uint256(_ro.cumulativeGasUsed).encodeUint(),
            _ro.bloom.encodeBytes(),
            _rlp
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeAccessList(
        Types.AccessList memory _accessList
    ) internal pure returns (bytes memory) {
        bytes memory _rlp;
        bytes memory temp;

        for (uint256 i = 0; i < _accessList.storageKeys.length; i++) {
            temp = abi.encodePacked(_accessList.storageKeys[i]).encodeBytes();
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi.encodePacked(addLength(_rlp.length, false), _rlp);
        _rlp = abi.encodePacked(_accessList._address.encodeAddress(), _rlp);
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeTransactionObject(
        Types.RLPTransactionObject memory _transactionObject
    ) internal pure returns (bytes memory) {
        bytes memory _rlp;
        bytes memory _rlpSig;
        bytes memory temp;

        for (uint256 i = 0; i < _transactionObject.accesslist.length; i++) {
            temp = _transactionObject.accesslist[i].encodeAccessList();
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi.encodePacked(addLength(_rlp.length, false), _rlp);

        _rlp = abi.encodePacked(
            _transactionObject.chainId.encodeUint(),
            _transactionObject.nonce.encodeUint(),
            _transactionObject.maxPriorityFeePerGas.encodeUint(),
            _transactionObject.maxFeePerGas.encodeUint(),
            _transactionObject.gas.encodeUint(),
            _transactionObject.to.encodeAddress(),
            _transactionObject.value.encodeUint(),
            _transactionObject.input.encodeBytes(),
            _rlp
        );

        bytes memory _rsEncode = abi.encodePacked(
            abi.encodePacked(_transactionObject.r).encodeBytes(),
            abi.encodePacked(_transactionObject.s).encodeBytes()
        );

        bytes memory _vEncode = abi.encodePacked(
            abi.encodePacked(_transactionObject.v.encodeBool())
        );
        _rlpSig = abi.encodePacked(_vEncode, _rsEncode);

        _rlp = abi.encodePacked(_rlp, _rlpSig);

        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    //  Adding LIST_HEAD_START by length
    //  There are two cases:
    //  1. List contains less than or equal 55 elements (total payload of the RLP) -> LIST_HEAD_START = LIST_SHORT_START + [0-55] = [0xC0 - 0xF7]
    //  2. List contains more than 55 elements:
    //  - Total Payload = 512 elements = 0x0200
    //  - Length of Total Payload = 2
    //  => LIST_HEAD_START = \x (LIST_LONG_START + length of Total Payload) \x (Total Payload) = \x(F7 + 2) \x(0200) = \xF9 \x0200 = 0xF90200
    function addLength(
        uint256 length,
        bool isLongList
    ) internal pure returns (bytes memory) {
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
