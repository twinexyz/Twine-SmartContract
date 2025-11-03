// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {MessageLibType} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLib.sol";
import {PacketV1Codec} from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";
import {IReceiveUlnE2} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/interfaces/IReceiveUlnE2.sol";
import {ILayerZeroDVN} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/interfaces/ILayerZeroDVN.sol";
import {ILayerZeroEndpointV2, Origin} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import {ITwineDVN} from "./interfaces/ITwineDVN.sol";
import {ISendLib, ISendLib} from "./interfaces/ISendLib.sol";
import {IL2TwineMessenger} from "../L2/IL2TwineMessenger.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";

contract TwineDVN is ILayerZeroDVN, ITwineDVN, ContextUpgradeable {
    using PacketV1Codec for bytes;

    // State Variables
    ILayerZeroEndpointV2 public layerZeroEndpointV2;
    uint32 public localEid;
    uint64 public blockConfirmations;
    address public roleManager;
    address public feeReceiver;
    address public lzMessageSender;
    address[] internal lzMessageLibs;

    // Structs
    struct MessageLibInfo {
        bool enabled;
        MessageLibType libType;
        address lib;
    }

    // Mappings
    mapping(uint32 => uint256) public chainFeeLookup;
    mapping(uint32 => bool) public supportedDstChain;
    mapping(address => MessageLibInfo) internal messageLibLookup;

    // Errors
    error ZeroAddress();
    error InsufficientFee();
    error InvalidParameters();
    error UnsupportedSendLib();
    error AlreadySet();
    error MessageLibAlreadyDeleted();
    error UnsupportedChain(uint32 dstEid);
    error InvalidSender(address lzMessageSender,address requiredSender);

    // Modifiers
    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    // Constructor
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Initialization
    function initialize(
        uint64 _blockConfirmations,
        address _layerZeroEndpointV2,
        address _roleManager,
        address _lzMessageSender
    ) public initializer {
        if (_layerZeroEndpointV2 == address(0)) revert ZeroAddress();

        layerZeroEndpointV2 = ILayerZeroEndpointV2(_layerZeroEndpointV2);
        localEid = layerZeroEndpointV2.eid();
        roleManager = _roleManager;
        blockConfirmations = _blockConfirmations;
        lzMessageSender = _lzMessageSender;
    }

    // External Functions
    /// @inheritdoc ILayerZeroDVN
    function assignJob(
        AssignJobParam calldata _param,
        bytes calldata /*_options*/
    ) external payable returns (uint256 fee) {
        if (_param.sender != lzMessageSender) {
            revert InvalidSender(lzMessageSender, _param.sender);
        }
        if (!supportedDstChain[_param.dstEid]) {
            revert UnsupportedChain(_param.dstEid);
        }
        if (!isSupportedMessageLib(msg.sender)) {
            revert UnsupportedSendLib();
        }

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
        uint64 /*_confirmations*/,
        address /*_sender*/,
        bytes calldata /*_options*/
    )
        external
        view
        onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN())
        returns (uint256 fee)
    {
        fee = chainFeeLookup[_dstEid];
    }

    /// @inheritdoc ITwineDVN
    function validatePayload(
        bytes calldata lzPayload
    )
        external
        onlyRoles(IRoleManager(roleManager).TWINE_MESSENGER())
        returns (bool)
    {
        bytes calldata packetHeader = lzPayload.header();
        bytes32 payloadHash = lzPayload.payloadHash();

        address receiverAddress = address(
            uint160(uint256(lzPayload.receiver()))
        );

        (address receiverLib, ) = layerZeroEndpointV2.getReceiveLibrary(
            receiverAddress,
            lzPayload.dstEid()
        );

        IReceiveUlnE2(receiverLib).verify(
            packetHeader,
            payloadHash,
            blockConfirmations
        );

        IReceiveUlnE2(receiverLib).commitVerification(
            packetHeader,
            payloadHash
        );

        Origin memory origin = Origin({
            srcEid: lzPayload.srcEid(),
            sender: lzPayload.sender(),
            nonce: lzPayload.nonce()
        });

        ILayerZeroEndpointV2(layerZeroEndpointV2).lzReceive(
            origin,
            receiverAddress,
            lzPayload.guid(),
            lzPayload.message(),
            bytes("")
        );

        emit PayloadVerified(packetHeader, lzPayload.payloadHash());

        return true;
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
        if (_dstEid.length != _price.length) {
            revert InvalidParameters();
        }

        for (uint256 i = 0; i < _dstEid.length; i++) {
            chainFeeLookup[_dstEid[i]] = _price[i];
            emit SetFee(_dstEid[i], _price[i]);
        }
    }

    function setDstChain(
        uint32 _dstEid,
        bool enabled
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (supportedDstChain[_dstEid] == enabled) {
            revert AlreadySet();
        }

        supportedDstChain[_dstEid] = enabled;
        emit DstChainStatusChanged(_dstEid, enabled);
    }

    function setFeeReceiver(
        address _feeReceiver
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_feeReceiver == address(0)) {
            revert ZeroAddress();
        }
        feeReceiver = _feeReceiver;
    }

    function setRoleManger(
        address _roleManager
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_roleManager == address(0)) {
            revert ZeroAddress();
        }
        roleManager = _roleManager;
    }

    function setBlockConfirmations(
        uint64 _blockConfirmations
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        blockConfirmations = _blockConfirmations;
    }

    function setLzMessageSender(
        address _lzMessageSender
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_lzMessageSender == address(0)) {
            revert ZeroAddress();
        }
        lzMessageSender = _lzMessageSender;
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
        if (!messageLibLookup[_messageLib].enabled) {
            revert MessageLibAlreadyDeleted();
        }

        messageLibLookup[_messageLib].enabled = false;
        uint256 fee = ISendLib(_messageLib).fees(address(this));

        if (fee > 0) {
            ISendLib(_messageLib).withdrawFee(payable(feeReceiver), fee);
            emit WithdrawFee(_messageLib, feeReceiver, fee);
        }
    }

    // Public Functions
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

    // Internal Functions
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

    // Storage Gap
    /// @dev The storage slots for future usage.
    uint256[49] private __gap;
}
