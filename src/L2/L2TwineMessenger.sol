// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IL2MsgExecutor} from "./IL2MsgExecutor.sol";
import {ITwineERC20} from "../libraries/token/ITwineERC20.sol";
import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {ITwineSystemStorage} from "./ITwineSystemStorage.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {IL2ERC20Gateway} from "./gateways/interfaces/IL2ERC20Gateway.sol";
import {TypeConversionLib} from "../libraries/utils/TypeConversionLib.sol";
import {ZstdCompressor} from "../libraries/utils/ZstdCompressor.sol";
import {TwineL2MessengerBase} from "../libraries/messenger/TwineL2MessengerBase.sol";
import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";

contract L2TwineMessenger is TwineL2MessengerBase, IL2TwineMessenger, ZstdCompressor {
    using TypeConversionLib for address;

    /// @notice SP1 Verifier Address
    address public sp1Verifier;

    /// @notice msg Executor Address
    address public msgExecutor;

    /// @notice Skip zk Verification
    bool public skipVerification;

    /// @notice The address of the system contract
    address public systemStorageContract;

    /// @notice The address of Consensus Proving Precompile
    address public consensusPrecompileAddress;

    /// @notice The address of bridging Precompile
    address public bridgingPrecompileAddress;

    /// @notice Mapping to store consensus verification keys of L1s
    mapping(uint256 => bytes32) public vKeys;

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 chaindId,
        address counterpartMessenger,
        address roleManager,
        address msgExecutorAddress
    ) external initializer {
        ZstdCompressor.__ZstdCompressor__init(address(0x18));
        TwineL2MessengerBase.__TwineMessengerBase_init(
            chaindId,
            counterpartMessenger,
            roleManager
        );
        consensusPrecompileAddress = address(0x15);
        bridgingPrecompileAddress = address(0x16);
        msgExecutor = msgExecutorAddress;
        systemStorageContract = address(0x17);
        skipVerification = true;
    }

    function setPrecompileAddress(
        address _consensusPrecompileAddress,
        address _bridgingPrecompileAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(
            _consensusPrecompileAddress != address(0),
            "Consensus precompile address cannot be zero"
        );
        require(
            _bridgingPrecompileAddress != address(0),
            "Bridging precompile address cannot be zero"
        );
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
        require(
            sp1VerifierAddress != address(0),
            "sp1Verifier address cannot be zero"
        );
        sp1Verifier = sp1VerifierAddress;
    }

    function setSystemStorageContract(
        address systemStorageContractAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(
            systemStorageContractAddress != address(0),
            "System Storage ContractAddress cannot be zero"
        );
        systemStorageContract = systemStorageContractAddress;
    }

    function setMsgExecutorAddress(
        address msgExecutorAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(
            msgExecutorAddress != address(0),
            "msgExecutor address cannot be zero"
        );
        msgExecutor = msgExecutorAddress;
    }

    function setVkeys(
        uint256 chainId,
        bytes32 vKey
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        vKeys[chainId] = vKey;
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
        handleBridgeTransactions(chainId, ChainType.Solana, txnOutput);
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
            ITwineSystemStorage(systemStorageContract).setBlockReceipts(
                chainId,
                height,
                receiptRoot
            );
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
            handleBridgeTransactions(chainId, ChainType.Ethereum, txnOutput);
        }
    }

    function handleBridgeTransactions(
        uint256 chainId,
        ChainType chainType,
        bytes memory precompileOutput
    ) internal {
        L1Txns memory l1Txn = abi.decode(precompileOutput, (L1Txns));
        uint256 nonce = l1Txn.nonce;
        address to = l1Txn.tokenTxn.receiver;
        address token = l1Txn.tokenTxn.token;
        uint256 amount = l1Txn.tokenTxn.amount;
        bool shouldMint = l1Txn.tokenTxn.deposit;

        if (shouldMint) {
            _checkAndUpdateNonce(
                chainId,
                nonce,
                ITwineSystemStorage.L1TxnType.Deposit
            );

            try this.mintAndCall(chainType, token, to, amount, l1Txn.contractCallData) {
                // success
            } catch (bytes memory lowLevelError) {
                if (chainType == ChainType.Ethereum) {
                    emit EthereumTransactionsHandled(0, nonce, lowLevelError);
                } else {
                    emit SolanaTransactionsHandled(0, nonce, lowLevelError);
                }
                return;
            }
        } else {
            _checkAndUpdateNonce(
                chainId,
                nonce,
                ITwineSystemStorage.L1TxnType.ForcedWithdraw
            );

            try ITwineERC20(token).burn(to, amount) {
                // Success
            } catch (bytes memory lowLevelError) {
                if (chainType == ChainType.Ethereum) {
                    emit EthereumTransactionsHandled(0, nonce, lowLevelError);
                } else {
                    emit SolanaTransactionsHandled(0, nonce, lowLevelError);
                }
                return;
            }
        }
        if (chainType == ChainType.Ethereum) {
            emit EthereumTransactionsHandled(1, nonce, precompileOutput);
        } else {
            emit SolanaTransactionsHandled(1, nonce, precompileOutput);
        }
    }

    function _checkAndUpdateNonce(
        uint256 chainId,
        uint256 nonce,
        ITwineSystemStorage.L1TxnType txnType
    ) internal {
        uint256 expectedNonce = ITwineSystemStorage(systemStorageContract)
            .getLastMessageExecuted(chainId, txnType);
        require(expectedNonce + 1 == nonce, "Invalid nonce");

        ITwineSystemStorage(systemStorageContract).increaseNonce(
            chainId,
            txnType
        );
    }

    function mintAndCall(
        ChainType chainType,
        address token,
        address to,
        uint256 amount,
        bytes memory contractCallData
    ) external {
        require(msg.sender == address(this), "Only self-call allowed");

        if ( chainType == ChainType.Solana ) {
            bytes memory output = _decompress(contractCallData);
            contractCallData = output;
        }

        ITwineERC20(token).mint(to, amount);


        if (contractCallData.length > 0) {
            ContractCall[] memory contractCallsArray = abi.decode(contractCallData, (ContractCall[]));
            IL2MsgExecutor(msgExecutor).processMessage(contractCallsArray);

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
