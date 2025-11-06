// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {ISP1Helios} from "./ISP1Helios.sol";
import {IL2MsgExecutor} from "./IL2MsgExecutor.sol";
import {IL2TwineMessenger} from "./IL2TwineMessenger.sol";
import {TwineTypes} from "../libraries/types/TwineTypes.sol";
import {ITwineSystemStorage} from "./ITwineSystemStorage.sol";
import {ITwineERC20} from "../libraries/token/ITwineERC20.sol";
import {ITwineDVN} from "../layerzero/interfaces/ITwineDVN.sol";
import {IRoleManager} from "../libraries/access/IRoleManager.sol";
import {ZstdCompressor} from "../libraries/utils/ZstdCompressor.sol";
import {MessageHasherLib} from "../libraries/utils/MessageHasherLib.sol";
import {IL2ERC20Gateway} from "./gateways/interfaces/IL2ERC20Gateway.sol";
import {TypeConversionLib} from "../libraries/utils/TypeConversionLib.sol";
import {TwineL2MessengerBase} from "../libraries/messenger/TwineL2MessengerBase.sol";
import {ITwineL2MessengerBase} from "../libraries/messenger/ITwineL2MessengerBase.sol";
import {PacketV1Codec} from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";

contract L2TwineMessenger is
    TwineL2MessengerBase,
    IL2TwineMessenger,
    ZstdCompressor
{
    using PacketV1Codec for bytes;
    using TypeConversionLib for string;
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

    /// @notice Address of sp1 helios
    address public sp1Helios;

    /// @notice Address of twine dvn
    address public twineDvn;

    /// @notice Mapping to store consensus verification keys of L1s
    mapping(uint256 => bytes32) public vKeys;

    /// @notice Mapping of message index to message hash
    mapping(uint256 => bytes32) public messageHash;

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

    function setSP1Helios(
        address _sp1Helios
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(_sp1Helios != address(0), "_sp1Helios address cannot be zero");
        sp1Helios = _sp1Helios;
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

    function setDvn(
        address dvnAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        require(
            dvnAddress != address(0),
            "DVN address cannot be zero"
        );
        twineDvn = dvnAddress;
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
        bytes32 prevRollingHash,
        TwineTypes.MessageData memory messageData,
        bytes memory publicValues,
        bytes memory proof
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
        uint64 chainId = messageData.chainId;

        bytes32 solMessageHash = MessageHasherLib.hashL1Message(messageData);
        require(
            !ITwineSystemStorage(systemStorageContract).isMessageHandled(
                solMessageHash
            ),
            "Message already executed"
        );

        if (!skipVerification) {
            ISP1Verifier(sp1Verifier).verifyProof(
                vKeys[uint256(chainId)],
                publicValues,
                proof
            );
        }

        bytes memory precompileInput = abi.encode(
            chainId,
            abi.encode(prevRollingHash, messageData, publicValues)
        );

        (bool txnSuccess, bytes memory txnOutput) = bridgingPrecompileAddress
            .call(precompileInput);
        require(txnSuccess, "Failed executing transactions");
        handleBridgeTransactions(chainId, solMessageHash, txnOutput);
    }

    /// @inheritdoc IL2TwineMessenger
    function handleEthereumProofAndTransactions(
        uint256 proofHeight,
        TwineTypes.MessageData memory messageData,
        bytes memory serializedProof
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
        uint256 latest_block = ISP1Helios(sp1Helios)
            .latestExecutionBlockNumber();
        require(latest_block >= proofHeight, "Block not yet provable");

        bytes32 ethMessageHash = MessageHasherLib.hashL1Message(messageData);
        require(
            !ITwineSystemStorage(systemStorageContract).isMessageHandled(
                ethMessageHash
            ),
            "Message already executed"
        );

        bytes32 stateRoot = ISP1Helios(sp1Helios).executionStateRoots(
            proofHeight
        );

        uint64 chainId = messageData.chainId;

        bytes memory precompile_input = abi.encode(
            chainId,
            abi.encode(proofHeight, stateRoot, messageData, serializedProof)
        );
        (bool txnSuccess, bytes memory txnOutput) = bridgingPrecompileAddress
            .call(precompile_input);
        require(txnSuccess, "Ethereum Transactions failed!");
        handleBridgeTransactions(chainId, ethMessageHash, txnOutput);
    }

    function handleLayerZeroTransactions(
        uint256 proofHeight,
        bytes calldata lzPayload,
        bytes memory lzPayloadProof
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
        uint256 latest_block = ISP1Helios(sp1Helios)
            .latestExecutionBlockNumber();
        require(latest_block >= proofHeight, "Block not yet provable");

        bytes32 stateRoot = ISP1Helios(sp1Helios).executionStateRoots(
            proofHeight
        );

        bytes memory msgBytes = bytes(packet.message());
        TwineTypes.MessageData memory messageData = abi.decode(msgBytes, (TwineTypes.MessageData));
        uint256 srcChainId = messageData.chainId;

        bytes memory precompile_input = abi.encode(
            srcChainId,
            abi.encode(proofHeight, stateRoot, messageData, lzPayloadProof)
        );

        (bool txnSuccess, ) = bridgingPrecompileAddress.call(precompile_input);
        require(txnSuccess, "LayerZero Transaction verification failed!");
        ITwineDVN(twineDvn).validatePayload(
           lzPayload
        );
        emit LayerzeroTransactionHandled(srcChainId, lzPayload.guid());
    }

    /// @notice This function is exclusively for mock testing and should never be deployed
    function handleChainTransactions(
        TwineTypes.MessageData memory messageData
    )
        external
        nonReentrant
        onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER())
    {
        bytes32 calculatedMessageHash = MessageHasherLib.hashL1Message(
            messageData
        );
        require(
            !ITwineSystemStorage(systemStorageContract).isMessageHandled(
                calculatedMessageHash
            ),
            "Message already executed"
        );
        bytes memory txnOutput = abi.encode(createL1Txns(messageData));

        handleBridgeTransactions(
            messageData.chainId,
            calculatedMessageHash,
            txnOutput
        );
    }

    function handleBridgeTransactions(
        uint256 chainId,
        bytes32 bridgeMessageHash,
        bytes memory precompileOutput
    ) internal {
        L1Txns memory l1Txn = abi.decode(precompileOutput, (L1Txns));
        uint256 nonce = uint256(l1Txn.nonce);
        address to = l1Txn.tokenTxn.receiver;
        address token = l1Txn.tokenTxn.token;
        uint256 amount = l1Txn.tokenTxn.amount;
        bool shouldMint = l1Txn.tokenTxn.deposit;

        if (shouldMint) {
            _checkAndUpdateNonce(chainId, nonce);

            try this.mintAndCall(token, to, amount, l1Txn.contractCallData) {
                // success
                ITwineSystemStorage(systemStorageContract).setMessageExecuted(
                    bridgeMessageHash,
                    ITwineSystemStorage.L1MessageStatus.Executed
                );
            } catch (bytes memory lowLevelError) {
                ITwineSystemStorage(systemStorageContract).setMessageExecuted(
                    bridgeMessageHash,
                    ITwineSystemStorage.L1MessageStatus.Failed
                );
                emit TransactionFailed(lowLevelError);
                emit L1TransactionsHandled(chainId, 0, nonce, precompileOutput);
                return;
            }
        } else {
            _checkAndUpdateNonce(chainId, nonce);

            try ITwineERC20(token).burn(to, amount) {
                // Success
                ITwineSystemStorage(systemStorageContract).setMessageExecuted(
                    bridgeMessageHash,
                    ITwineSystemStorage.L1MessageStatus.Executed
                );
            } catch (bytes memory lowLevelError) {
                ITwineSystemStorage(systemStorageContract).setMessageExecuted(
                    bridgeMessageHash,
                    ITwineSystemStorage.L1MessageStatus.Failed
                );
                emit TransactionFailed(lowLevelError);
                emit L1TransactionsHandled(chainId, 0, nonce, precompileOutput);
                return;
            }
        }

        emit L1TransactionsHandled(chainId, 1, nonce, precompileOutput);
    }

    function _checkAndUpdateNonce(uint256 chainId, uint256 nonce) internal {
        uint256 expectedNonce = ITwineSystemStorage(systemStorageContract)
            .getLastMessageExecuted(chainId);
        require(expectedNonce + 1 == nonce, "Invalid nonce");

        ITwineSystemStorage(systemStorageContract).increaseNonce(chainId);
    }

    function mintAndCall(
        address token,
        address to,
        uint256 amount,
        bytes memory contractCallData
    ) external {
        require(msg.sender == address(this), "Only self-call allowed");

        //@ add token mapping check here

        ITwineERC20(token).mint(to, amount);

        if (contractCallData.length > 0) {
            bytes memory output = _decompress(contractCallData);
            contractCallData = output;

            ContractCall[] memory contractCallsArray = abi.decode(
                contractCallData,
                (ContractCall[])
            );
            IL2MsgExecutor(msgExecutor).processMessage(contractCallsArray);
        }
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
        messageHash[messageCount] = computeTransactionHash(
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

    function computeTransactionHash(
        address from,
        address l2Token,
        string memory to,
        string memory l1Token,
        uint256 amount,
        uint256 value,
        uint256 messageCount,
        uint256 chainId,
        uint256 blockNumber,
        uint256 gasLimit
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    from,
                    l2Token,
                    to,
                    l1Token,
                    amount,
                    value,
                    messageCount,
                    chainId,
                    blockNumber,
                    gasLimit
                )
            );
    }

    function createL1Txns(
        TwineTypes.MessageData memory messageData
    ) internal pure returns (L1Txns memory) {
        TwineTypes.TransactionType txnType = messageData.txnType;

        if (
            txnType != TwineTypes.TransactionType.Deposit &&
            txnType != TwineTypes.TransactionType.Withdraw
        ) {
            revert("transaction type not supported");
        }

        bool is_deposit = (txnType == TwineTypes.TransactionType.Deposit);

        return
            L1Txns({
                nonce: messageData.nonce,
                tokenTxn: TokenTxn({
                    token: messageData.l2Token.stringToAddress(),
                    receiver: messageData.toAddress.stringToAddress(),
                    deposit: is_deposit,
                    amount: messageData.amount.stringToUint()
                }),
                l1Metadata: L1Metadata({
                    blockHeight: messageData.blockNumber,
                    fromAddress: messageData.fromAddress,
                    l1Token: messageData.l1Token
                }),
                contractCallData: messageData.message
            });
    }

    function decodePayloadData(
        bytes calldata payloadData
    )
        internal
        pure
        returns (DecodedPayload memory decoded, bytes calldata packetHeader)
    {
        (uint32 dstEid, bytes memory remainingData) = abi.decode(
            payloadData,
            (uint32, bytes)
        );

        uint64 blockConfirmations;
        address receiverAddress;
        bytes32 payloadHash;

        (blockConfirmations, receiverAddress, , , payloadHash, ) = abi.decode(
            remainingData,
            (uint64, address, uint256, uint256, bytes32, bytes32)
        );

        // Fixed fields before packetHeader:
        // 2 * 32 (dstEid encoding) + 8 * 32 (remaining fields) = 320 bytes = 0x140
        packetHeader = payloadData[0x140:];

        decoded = DecodedPayload({
            dstEid: dstEid,
            blockConfirmations: blockConfirmations,
            receiverAddress: receiverAddress,
            payloadHash: payloadHash
        });

        return (decoded, packetHeader);
    }
}
