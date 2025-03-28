// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineDVN} from "./interfaces/ITwineDVN.sol";
import {ILayerZeroDVN} from "./interfaces/ILayerZeroDVN.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {ISendLib, MessageLibType} from "./interfaces/ISendLib.sol";
import {ILayerZeroEndpointV2} from "./interfaces/ILayerZeroEndpointV2.sol";
import {IReceiveUlnE2, Verification, UlnConfig} from "./interfaces/IReceiveUlnE2.sol";

contract TwineDVN is ILayerZeroDVN, ITwineDVN, ContextUpgradeable {
    ILayerZeroEndpointV2 public layerZeroEndpointV2;

    address roleManager;
    uint32 public localEid;
    address feeReceiver;
    address[] internal lzMessageLibs;

    struct MessageLibInfo {
        bool enabled;
        MessageLibType libType;
        address lib;
    }

    // eid=>fee
    mapping(uint32 => uint256) public chainFeeLookup;
    // eid=>bool
    mapping(uint32 => bool) public supportedDstChain;
    mapping(address => MessageLibInfo) internal messageLibLookup;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    error ZeroAddress();
    error InsufficientFee();
    error InvalidParameters();
    error UnsupportedSendLib();
    error AlreadySet();
    error MessageLibAlreadyDeleted();
    error UnsupportedChain(uint32 dstEid);

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _layerZeroEndpointV2,
        address _roleManager
    ) public initializer {
        if (_layerZeroEndpointV2 == address(0)) revert ZeroAddress();
        layerZeroEndpointV2 = ILayerZeroEndpointV2(_layerZeroEndpointV2);
        localEid = layerZeroEndpointV2.eid();
        roleManager = _roleManager;
    }

    /// @inheritdoc ILayerZeroDVN
    function assignJob(
        AssignJobParam calldata _param,
        bytes calldata /*_options*/
    ) external payable returns (uint256 fee) {
        if (!supportedDstChain[_param.dstEid])
            revert UnsupportedChain(_param.dstEid);
        if (!isSupportedMessageLib(msg.sender)) revert UnsupportedSendLib();
        fee = chainFeeLookup[_param.dstEid];
        (bytes32 guId, address receiver) = getIDAddress(_param.packetHeader);
        emit TwineNotified(
            _param.dstEid,
            _param.confirmations,
            receiver,
            fee,
            block.number,
            _param.payloadHash,
            guId,
            _param.packetHeader
        );
    }

    /// @inheritdoc ILayerZeroDVN
    function getFee(
        uint32 _dstEid,
        uint64,
        /*_confirmations*/ address,
        /*_sender*/ bytes calldata /*_options*/
    ) external view returns (uint256 fee) {
        fee = chainFeeLookup[_dstEid];
    }

    /// @inheritdoc ITwineDVN
    function validatePayload(
        bytes memory payloadData
    )
        external
        onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN())
        returns (bool)
    {
        PayloadOtherData memory data = getPayloadOtherData(payloadData);
        (address receiverLib, ) = layerZeroEndpointV2.getReceiveLibrary(
            data.receiverAddress,
            data.dstEid
        );
        IReceiveUlnE2(receiverLib).verify(
            data.packetHeader,
            data.payloadHash,
            data.blockConfirmations
        );
        emit PayloadVerified(data.packetHeader, data.payloadHash);
        return true;
    }

    function isSupportedMessageLib(
        address _messageLib
    ) public view returns (bool) {
        return messageLibLookup[_messageLib].enabled;
    }

    function getLzMessageLibLength() public view returns (uint256) {
        return lzMessageLibs.length;
    }

    function getLzMessageLib(
        address _msgLib
    ) public view returns (MessageLibInfo memory) {
        return messageLibLookup[_msgLib];
    }

    function feeBalance() public view returns (uint256 balance) {
        for (uint256 i = 0; i < getLzMessageLibLength(); i++) {
            address _messageLib = lzMessageLibs[i];
            if (messageLibLookup[_messageLib].enabled) {
                balance += ISendLib(_messageLib).fees(address(this));
            }
        }
    }

    function withdrawFeeAll(
        address payable _to
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        uint256 _amount = 0;
        for (uint256 i = 0; i < getLzMessageLibLength(); i++) {
            address _messageLib = lzMessageLibs[i];
            if (!isSupportedMessageLib(_messageLib)) {
                continue;
            }
            uint256 ulnBalance = ISendLib(_messageLib).fees(address(this));
            if (ulnBalance > 0) {
                ISendLib(_messageLib).withdrawFee(_to, ulnBalance);
                emit WithdrawFee(_messageLib, _to, ulnBalance);
                _amount += ulnBalance;
            }
        }
        if (_amount == 0) {
            revert InsufficientFee();
        }
    }

    function withdrawFee(
        address _messageLib,
        address payable _to
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        uint256 _fee = ISendLib(_messageLib).fees(address(this));
        if (_fee == 0) {
            revert InsufficientFee();
        }
        ISendLib(_messageLib).withdrawFee(_to, _fee);

        emit WithdrawFee(_messageLib, _to, _fee);
    }

    function setFees(
        uint32[] calldata _dstEid,
        uint256[] calldata _price
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_dstEid.length != _price.length) revert InvalidParameters();
        for (uint256 i = 0; i < _dstEid.length; i++) {
            chainFeeLookup[_dstEid[i]] = _price[i];
            emit SetFee(_dstEid[i], _price[i]);
        }
    }

    function setDstChain(
        uint32 _dstEid,
        bool enabled
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (supportedDstChain[_dstEid] == enabled) revert AlreadySet();

        supportedDstChain[_dstEid] = enabled;
        emit DstChainStatusChanged(_dstEid, enabled);
    }

    function setFeeReceiver(
        address _feeReceiver
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_feeReceiver == address(0)) revert ZeroAddress();
        feeReceiver = _feeReceiver;
    }

    function addLzMessageLib(
        address _messageLib
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        messageLibLookup[_messageLib] = MessageLibInfo(
            true,
            MessageLibType.Send,
            _messageLib
        );
        lzMessageLibs.push(_messageLib);
    }

    function removeLzMessageLib(
        address _messageLib
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (!messageLibLookup[_messageLib].enabled)
            revert MessageLibAlreadyDeleted();

        messageLibLookup[_messageLib].enabled = false;
        uint256 fee = ISendLib(_messageLib).fees(address(this));
        if (fee > 0) {
            ISendLib(_messageLib).withdrawFee(payable(feeReceiver), fee);
            emit WithdrawFee(_messageLib, feeReceiver, fee);
        }
    }

    function getPayloadOtherData(
        bytes memory otherData
    ) internal pure returns (PayloadOtherData memory) {
        (uint32 dstEid,bytes memory reaminingData) = abi.decode(otherData,(uint32,bytes));
        (
            uint64 blockConfirmations,
            address receiverAddress,
            ,
            ,
            bytes32 payloadHash,
            ,
            bytes memory packetHeader
        ) = abi.decode(
                reaminingData,
                (
                    uint64,
                    address,
                    uint256,
                    uint256,
                    bytes32,
                    bytes32,
                    bytes
                )
            );

        return
            PayloadOtherData(
                dstEid,
                blockConfirmations,
                receiverAddress,
                payloadHash,
                packetHeader
            );
    }

    function getIDAddress(
        bytes memory _packetHeader
    ) internal pure returns (bytes32 guId, address receiverAddress) {
        uint8 version;
        uint64 nonce;
        uint32 srcEid;
        bytes32 sender;
        uint32 dstEid;
        bytes32 receiver;
        assembly {
            version := mload(add(_packetHeader, 1))
            nonce := mload(add(_packetHeader, 9))
            srcEid := mload(add(_packetHeader, 13))
            sender := mload(add(_packetHeader, 45))
            dstEid := mload(add(_packetHeader, 49))
            receiver := mload(add(_packetHeader, 81))
        }
        guId = keccak256(
            abi.encodePacked(nonce, srcEid, sender, dstEid, receiver)
        );
        receiverAddress = address(uint160(uint256(receiver)));
    }

    function getPayloadOtherDataTest(
        bytes memory otherData
    ) external pure returns (PayloadOtherData memory) {
        (
            uint32 dstEid,
            uint64 blockConfirmations,
            address receiverAddress,
            ,
            ,
            bytes32 payloadHash,
            ,
            bytes memory packetHeader
        ) = abi.decode(
                otherData,
                (
                    uint32,
                    uint64,
                    address,
                    uint256,
                    uint256,
                    bytes32,
                    bytes32,
                    bytes
                )
            );

        return
            PayloadOtherData(
                dstEid,
                blockConfirmations,
                receiverAddress,
                payloadHash,
                packetHeader
            );
    }
}
