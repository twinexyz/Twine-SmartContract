// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {IL1ERC20Gateway} from "../L1/gateways/interfaces/IL1ERC20Gateway.sol";
import {ITwineL2Gateway} from "../libraries/gateway/ITwineL2Gateway.sol";
import {TwineL2MessengerBase} from "../libraries/messenger/TwineL2MessengerBase.sol";
import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";
contract L2TwineMessenger is TwineL2MessengerBase, IL2TwineMessenger {
    /// @notice The address of Consensus Proving Precompile
    address public consensusPrecompileAddress;

    /// @notice The address of bridging Precompile
    address public bridgingPrecompileAddress;

    /// @notice Mapping from L1 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(bytes32 => bool) public isL1MessageExecuted;

    /// @notice Mapping to store the receipt roots for each block number
    mapping(uint256 => mapping(uint256 => bytes32)) public blockReceiptRoots;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _ethChaindId,
        address _ethCounterpart,
        address _roleManager
    ) external initializer {
        TwineL2MessengerBase.__TwineMessengerBase_init(
            _ethChaindId,
            _ethCounterpart,
            _roleManager
        );
    }

    function setPrecompileAddress(
        address _consensusPrecompileAddress,
        address _bridgingPrecompileAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        consensusPrecompileAddress = _consensusPrecompileAddress;
        bridgingPrecompileAddress = _bridgingPrecompileAddress;
    }

    /// @inheritdoc ITwineL2MessengerBase
    function sendMessage(
        address _from,
        address _l2Token,
        string memory _to,
        string memory _l1Token,
        uint256 _amount,
        uint256 _value,
        uint256 _chainId,
        uint256 _gasLimit
    ) external payable override {
        _sendMessage(
            _from,
            _l2Token,
            _to,
            _l1Token,
            _amount,
            _value,
            _chainId,
            _gasLimit
        );
    }

    function verifyConsensusProofAndExecuteDeposit(
        uint256 chainId,
        uint256 slotNumber,
        bytes32 bankHash,
        bytes memory consensusProof,
        bytes memory depositTransactions,
        bytes32 parityHash
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        // _verifyConsensusProof(consensusProof);
        blockReceiptRoots[chainId][slotNumber] =  bankHash;
        if (depositTransactions.length > 0) {
            bytes memory data = abi.encode(chainId, depositTransactions);
            (bool success, bytes memory output) = bridgingPrecompileAddress
                .call(data);
            require(success, "Deposits failed!");
            emit L1TokenDeposit();
            emit ParityHash(parityHash, block.number, blockhash(block.number));
        }
    }

    function executeForcedWithdrawal(
        uint256 chainId,
        bytes memory withdrawalTransaction,
        bytes32 parityHash
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        (bool success, bytes memory output) = bridgingPrecompileAddress.call(
            abi.encode(
                chainId,
                withdrawalTransaction
            )
        );
        require(success, "Withdrawal failed!");
        WithdrawalDetails memory details = _decodeWithdrawalDetails(output);

        emit ForcedWithdrawal(
            details.from,
            details.l2Token,
            addressToString(details.to),
            addressToString(details.l1Token),
            details.amount,
            details.value,
            chainId,
            block.number,
            0
        );
        emit ParityHash(parityHash, block.number, blockhash(block.number));
    }
    function verifyLayerZeroPayload(
        uint256 chainId,
        bytes memory lzPayload,
        bytes memory payloadProof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        bytes[] memory lzPayloads = new bytes[](1);
        bytes[] memory payloadProofs = new bytes[](1);
        lzPayloads[0] = lzPayload;
        payloadProofs[0] = payloadProof;
        (bool success, bytes memory output) = bridgingPrecompileAddress.call(
            abi.encode(chainId, lzPayloads, payloadProofs)
        );
        require(success, "LayerZero verification failed!");
        bytes32 guId = abi.decode(output, (bytes32));
        emit LayerzeroPayload(chainId, guId);
    }

    /// @dev Internal function to send cross domain message.
    /// @param _to The address of the contract to call.
    /// @param _value The amount of native token
    /// @param _gasLimit Optional gas limit to complete the message relay on corresponding chain.
    function _sendMessage(
        address _from,
        address _l2Token,
        string memory _to,
        string memory _l1Token,
        uint256 _amount,
        uint256 _value,
        uint256 _chainId,
        uint256 _gasLimit
    ) internal {
        emit SentMessage(
            _from,
            _l2Token,
            _to,
            _l1Token,
            _amount,
            _value,
            messageCount++,
            _chainId,
            block.number,
            _gasLimit
        );
    }

    function _verifyConsensusProof(bytes memory consensusProof) internal {
        (bool success, bytes memory output) = consensusPrecompileAddress.call(
            consensusProof
        );
        require(success, "Consensus proof Failed!");
        emit consensusVerified(consensusProof);
    }
    function _packWithdrawalData(
        bytes memory withdrawalTransaction,
        bytes memory proof
    ) internal pure returns (bytes memory) {
        return abi.encode(withdrawalTransaction, proof);
    }

    function _decodeWithdrawalDetails(
        bytes memory output
    ) internal pure returns (WithdrawalDetails memory) {
        (
            address l1Token,
            address l2Token,
            address from,
            address to,
            uint256 amount
        ) = abi.decode(output, (address, address, address, address, uint256));
        uint256 value;
        if (l1Token == address(0)) {
            value = amount;
        } else {
            value = 0;
        }
        return WithdrawalDetails(l1Token, l2Token, from, to, amount, value);
    }

    function addressToString(
        address _address
    ) public pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
     function stringToAddress(
        string memory _addressString
    ) public pure returns (address) {
        bytes memory stringBytes = bytes(_addressString);
        require(
            stringBytes.length == 42 &&
                stringBytes[0] == "0" &&
                stringBytes[1] == "x",
            "Invalid address format"
        );

        uint160 result = 0;
        for (uint i = 2; i < 42; i++) {
            result *= 16;
            uint8 digit = uint8(stringBytes[i]);
            if (digit >= 48 && digit <= 57) {
                result += (digit - 48);
            } else if (digit >= 65 && digit <= 70) {
                result += (digit - 55);
            } else if (digit >= 97 && digit <= 102) {
                result += (digit - 87);
            } else {
                revert("Invalid character in address string");
            }
        }
        return address(result);
    }
}
