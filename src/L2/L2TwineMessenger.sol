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

    /// @notice Mapping from L1 message hash to a boolean value indicating if the message has been successfully executed.
    mapping(uint256 => mapping(L1TxnType => uint256))
        public isL1MessageExecuted;

    /// @notice Mapping to store the receipt roots for each block number
    mapping(uint256 => mapping(uint256 => bytes32)) public blockReceiptRoots;

    /// @notice Mapping to store consensus verification keys of L1s
    mapping(uint256 => bytes32) public vKeys;

    /// @notice SP1 Verifier Address
    address public sp1Verifier;

    /// @notice Skip Verification For Testing
    bool public skipVerification;

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

    function setZkVerifyStatus(
        bool status
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        skipVerification = status;
    }

    function setSp1VerifierAddress(
        address _sp1VerifierAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        sp1Verifier = _sp1VerifierAddress;
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
    )
        external
        payable
        override
        onlyRoles(IRoleManager(roleManager).TWINE_GATEWAYS())
    {
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

    function handleSolanaTransactions(
        uint256 chainId,
        bytes calldata precompileInput
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
        (bool success, bytes memory output) = consensusPrecompileAddress.call(
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

        (bool txnSuccess, bytes memory txnOutput) = bridgingPrecompileAddress
            .call(output);
        require(txnSuccess, "Failed executing transactions");

        emit solanaTransactionsHandled(txnOutput);
    }

    function handleEthereumProofAndTransactions(
        uint256 chainId,
        bytes memory consensusProof,
        bytes memory ethereumTransactions
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
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
            emit ethereumTransactionsHandled(txnOutput);
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
        ISP1Verifier(sp1Verifier).verifyProof(
            vKeys[chainId],
            sp1Params.publicValue,
            sp1Params.proof
        );
        emit consensusVerified(consensusProof);
    }

    /// @notice decode the withdraw details
    function _decodeWithdrawalDetails(
        bytes memory output
    ) internal pure returns (WithdrawalDetails memory) {
        (
            uint256 l1Nonce,
            uint256 amount,
            address l2Token,
            string memory l1Token,
            string memory to,
            string memory from
        ) = abi.decode(
                output,
                (uint256, uint256, address, string, string, string)
            );

        return WithdrawalDetails(amount, l1Nonce, l2Token, to, l1Token, from);
    }
}
