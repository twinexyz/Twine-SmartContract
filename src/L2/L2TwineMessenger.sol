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
        address _to,
        address _counterpart,
        uint256 _value,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _message
    ) external payable override {
        _sendMessage(
            _from,
            _to,
            _counterpart,
            _value,
            _chainId,
            _gasLimit,
            _message
        );
    }

    function verifyConsensusProofAndExecuteDeposit(
        uint256 chainId,
        bytes memory consensusProof,
        bytes[] memory depositTransactions,
        bytes[] memory depositTxnProofs
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        _verifyConsensusProof(consensusProof);
        if (depositTransactions.length > 0) {
            bytes memory data = abi.encode(
                chainId,
                depositTransactions,
                depositTxnProofs
            );
            (bool success, bytes memory output) = bridgingPrecompileAddress.call(data);
            require(success, "Deposits failed!");
            emit L1TokenDeposit();
        }
    }

    function executeForcedWithdrawal(
        uint256 chainId,
        bytes memory withdrawalTransaction,
        bytes memory proof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        bytes[] memory withdrawalTxns = new bytes[](1);
        bytes[] memory proofs = new bytes[](1);
        withdrawalTxns[0] = withdrawalTransaction;
        proofs[0] = proof;
        (bool success, bytes memory output) = bridgingPrecompileAddress.call(
            abi.encode(chainId, withdrawalTxns, proofs)
        );
        require(success, "Withdrawal failed!");
        (WithdrawalDetails memory details) = _decodeWithdrawalDetails(output);
        
        emit ForcedWithdrawal(
            details.from,
            details.to,
            tokenCounterpartGateWay[chainId][details.l1Token],
            counterpartMessenger[chainId],
            details.value,
            chainId,
            block.number,
            0,
            abi.encodeCall(IL1ERC20Gateway.finalizeTokenWithdrawal,(details.l1Token,details.l2Token,details.from,details.to,details.amount,bytes(""))
            )
        );
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
            (bool success, bytes memory output) = bridgingPrecompileAddress.call(abi.encode(chainId, lzPayloads, payloadProofs));
            require(success, "LayerZero verification failed!");
            (bytes32 guId) = abi.decode(output,(bytes32));
            emit LayerzeroPayload(chainId,guId);
    }

    /// @dev Internal function to send cross domain message.
    /// @param _to The address of the contract to call.
    /// @param _value The amount of native token
    /// @param _counterpart The L1 token gateway
    /// @param _message The content of the message.
    /// @param _gasLimit Optional gas limit to complete the message relay on corresponding chain.
    function _sendMessage(
        address _from,
        address _to,
        address _counterpart,
        uint256 _value,
        uint256 _chainId,
        uint256 _gasLimit,
        bytes memory _message
    ) internal {
        emit SentMessage(
            _from,
            _to,
            _counterpart,
            counterpartMessenger[_chainId],
            _value,
            _chainId,
            block.number,
            _gasLimit,
            _message
        );
    }

    function _verifyConsensusProof(bytes memory consensusProof) internal {
        (bool success, bytes memory output) = consensusPrecompileAddress.call(
            consensusProof
        );
        require(success, "Consensus proof Failed!");
        emit consensusVerified(consensusProof);
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
        ) = abi.decode(
                output,
                (address, address, address, address, uint256)
            );
        uint256 value;
        if( l1Token == address(0)){
               value = amount;
            } else {
                value = 0;
         }
        return WithdrawalDetails(l1Token, l2Token, from, to, amount,value);
    }

}


