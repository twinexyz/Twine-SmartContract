// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineDVN} from "./interfaces/ITwineDVN.sol";
import {ILayerZeroDVN} from "./interfaces/ILayerZeroDVN.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {ISendLib, MessageLibType} from "./interfaces/ISendLib.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroEndpointV2} from "./interfaces/ILayerZeroEndpointV2.sol";
import { IReceiveUlnE2, Verification, UlnConfig } from "./interfaces/IReceiveUlnE2.sol";

contract TwineDVN is ILayerZeroDVN,ITwineDVN, ContextUpgradeable {
    ILayerZeroEndpoint public layerZeroEndpointV1;
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

    event SetFee(uint32 dstEid, uint256 fee);
    event DstChainStatusChanged(uint32 dstEid, bool enabled);
    event WithdrawFee(address messageLib, address receiver, uint256 amount);
    event TwineNotified(
        uint32 dstEid,
        uint64 blockConfirmations,
        address userApplication,
        uint256 fee
    );

    error ZeroAddress();
    error InsufficientFee();
    error InvalidParameters();
    error UnsupportedSendLib();
    error AlreadySet();
    error MessageLibAlreadyDeleted();
    error UnsupportedChain(uint32 dstEid);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _layerZeroEndpointV2,
        address _layerZeroEndpointV1,
        address _roleManager
    ) public initializer {
        if (_layerZeroEndpointV2 == address(0)) revert ZeroAddress();
        if (_layerZeroEndpointV1 == address(0)) revert ZeroAddress();
        layerZeroEndpointV2 = ILayerZeroEndpointV2(_layerZeroEndpointV2);
        layerZeroEndpointV1 = ILayerZeroEndpoint(_layerZeroEndpointV1);
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
        emit TwineNotified(
            _param.dstEid,
            _param.confirmations,
            _param.sender,
            fee
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

    function validatePayload(bytes memory payloadData)
        external
        onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN())
    {
        PayloadOtherData memory data = getPayloadOtherData(payloadData);
        require(data.requiredBlockNumber > block.number);
        IReceiveUlnE2(data.receiveLibrary).verify(data.packetHeader, data.payloadHash, data.blockConfirmation);
        emit PayloadVerified(data.packetHeader, data.payloadHash);
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

    function getPayloadOtherData(bytes memory otherData) internal returns (PayloadOtherData memory) {
        (uint64 blockConfirmation,
        uint120 requiredBlockNumber,
        address receiveLibrary,
        bytes32 payloadHash,
        bytes memory packetHeader) = abi.decode(otherData,(uint64,uint120,address,bytes32,bytes));

        return PayloadOtherData(blockConfirmation,requiredBlockNumber,receiveLibrary,payloadHash,packetHeader);


    }
}


