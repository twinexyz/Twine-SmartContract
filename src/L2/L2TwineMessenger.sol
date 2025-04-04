// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {TypeConversionLib} from "../libraries/utils/TypeConversionLib.sol";
import {TwineL2MessengerBase} from "../libraries/messenger/TwineL2MessengerBase.sol";
import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";

contract L2TwineMessenger is TwineL2MessengerBase, IL2TwineMessenger {
    using TypeConversionLib for address;

    /// @notice The address of Consensus Proving Precompile
    address public consensusPrecompileAddress;

    /// @notice The address of bridging Precompile
    address public bridgingPrecompileAddress;

    /// @notice mapping of (chainId => (L1TxnType => nonce))
    mapping(uint256 => mapping(L1TxnType => uint256))
        public l1MessageExecutedCount;

    /// @notice Mapping to store the receipt roots for each block number
    mapping(uint256 => mapping(uint256 => bytes32)) public blockReceiptRoots;

    /// @notice Mapping to store consensus verification keys of L1s
    mapping(uint256 => bytes32) public vKeys;

    /// @notice SP1 Verifier Address
    address public sp1Verifier;

    /// @notice Skip zk Verification
    bool public skipVerification;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 ethChaindId,
        address ethCounterpart,
        address roleManager
    ) external initializer {
        TwineL2MessengerBase.__TwineMessengerBase_init(
            ethChaindId,
            ethCounterpart,
            roleManager
        );
        consensusPrecompileAddress = address(0x16);
        bridgingPrecompileAddress = address(0x15);
        skipVerification = true;
    }

    function setPrecompileAddress(
        address _consensusPrecompileAddress,
        address _bridgingPrecompileAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        consensusPrecompileAddress = _consensusPrecompileAddress;
        bridgingPrecompileAddress = _bridgingPrecompileAddress;
    }

    function setZkVerifcationStatus(
        bool status
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        skipVerification = status;
    }

    function setSp1VerifierAddress(
        address sp1VerifierAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        sp1Verifier = sp1VerifierAddress;
    }

    /// @inheritdoc ITwineL2MessengerBase
    function sendMessage(
        address from,
        address l2Token,
        string memory to,
        string memory l1Token,
        uint256 amount,
        uint256 value,
        uint256 chainId,
        uint256 gasLimit
    )
        external
        payable
        override
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_GATEWAYS())
    {
        _sendMessage(
            from,
            l2Token,
            to,
            l1Token,
            amount,
            value,
            chainId,
            gasLimit
        );
    }

    function handleSolanaTransactions(
        uint256 chainId,
        bytes calldata precompileInput
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
        bytes memory output = precompileInput;
        bool success;
        
        if (!skipVerification) {
            (success, output) = consensusPrecompileAddress.call(
                precompileInput
            );
            require(success, "Consensus verification failed!");

            SolanaVerifierPrecompileOutput memory verifierOutput = abi.decode(
                output,
                (SolanaVerifierPrecompileOutput)
            );

            ISP1Verifier(sp1Verifier).verifyProof(
                vKeys[chainId],
                verifierOutput.publicValue,
                verifierOutput.proof
            );
        }

        (bool txnSuccess, bytes memory txnOutput) = bridgingPrecompileAddress
            .call(output);
        require(txnSuccess, "Failed executing transactions");

        emit SolanaTransactionsHandled(txnOutput);
    }

    function handleEthereumProofAndTransactions(
        uint256 chainId,
        uint256 height,
        bytes32 receiptRoot,
        bytes memory consensusProof,
        bytes memory ethereumTransactions
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
        // For testing purposes only. TODO: Remove before deploying to production.
        if (skipVerification) {
            blockReceiptRoots[chainId][height] = receiptRoot;
        }
        if (consensusProof.length > 0) {
            _verifyConsensusProof(chainId, consensusProof);
        }

        if (ethereumTransactions.length > 0) {
            bytes memory data = abi.encode(chainId, ethereumTransactions);
            (
                bool txnSuccess,
                bytes memory txnOutput
            ) = bridgingPrecompileAddress.call(data);
            require(txnSuccess, "Ethereum Transactions failed!");
            emit EthereumTransactionsHandled(txnOutput);
        }
    }

    function verifyLayerZeroPayload(
        uint256 chainId,
        bytes memory lzPayload,
        bytes memory payloadProof
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
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

    function setVkeys(
        uint256 chainId,
        bytes32 vKey
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        vKeys[chainId] = vKey;
    }

    /// @dev Internal function to send cross domain message.
    /// @param to The address of the contract to call.
    /// @param value The amount of native token
    /// @param gasLimit Optional gas limit to complete the message relay on corresponding chain.
    function _sendMessage(
        address from,
        address l2Token,
        string memory to,
        string memory l1Token,
        uint256 amount,
        uint256 value,
        uint256 chainId,
        uint256 gasLimit
    ) internal {
        ++messageCount;
        emit SentMessage(
            from,
            l2Token,
            to,
            l1Token,
            amount,
            value,
            messageCount,
            chainId,
            block.number,
            gasLimit
        );
    }

    /// @notice function to verify the consensus proof
    function _verifyConsensusProof(
        uint256 chainId,
        bytes memory consensusProof
    ) internal {
        (bool success, bytes memory output) = consensusPrecompileAddress.call(
            consensusProof
        );
        require(success, "Consensus proof parsing failed!");
        EthereumVerifierPrecompileOutput memory sp1Params = abi.decode(
            output,
            (EthereumVerifierPrecompileOutput)
        );
        if (!skipVerification) {
            ISP1Verifier(sp1Verifier).verifyProof(
                vKeys[chainId],
                sp1Params.publicValue,
                sp1Params.proof
            );
        }
        emit ConsensusVerified(consensusProof);
    }
}
