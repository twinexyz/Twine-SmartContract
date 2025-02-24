// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {ITwineDVN} from "../../lzdvn/interfaces/ITwineDVN.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";
import {IL1ETHGateway} from "../gateways/interfaces/IL1ETHGateway.sol";
import {IL1ERC20Gateway} from "../gateways/interfaces/IL1ERC20Gateway.sol";
import {TypeConversionLib} from "../../libraries/utils/TypeConversionLib.sol";

/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ContextUpgradeable, ITwineChain {
    using TypeConversionLib for string;

    /*************
     * Variables *
     *************/

    ///@notice The chai ID for the L1 where this contract is deployed
    uint256 public chainId;

    ///@notice current start block
    uint256 currentStartBlock;

    ///@notice current end block
    uint256 currentEndBlock;

    /// @notice The latest committed block number
    uint256 public override lastCommittedBlockNumber;

    /// @notice The latest finalized block number
    uint256 public override lastFinalizedBlockNumber;

    /// @notice The verification key for inclusion proof
    bytes32 public inclusionVKey;

    /// @notice The verification key for withdrawal proof
    bytes32 public withdrawalVKey;

    /// @notice The verification key for execution proof.
    bytes32 public executionVKey;

    //@notice The hash of the last committed block hash
    bytes32 public lastCommittedEndBlockHash;

    //@notice The last finalize batch hash
    bytes32 public lastFinalizedBatchHash;

    //gateway address of eth
    address public ethGateway;

    //gateway address of erc20 gateway
    address public ERC20Gateway;

    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

    /// @notice The address of RollupVerifier.
    address public verifier;

    /// @notice Address of the rolemanager contract
    address roleManager;

    /*************
     * Mappings  *
     *************/

    mapping(bytes32 => StoredBlockInfo[]) public commitedBlockInfo;
    /// @notice The mapping of batchNumber => CommittedBatches
    mapping(bytes32 => StoredBatchInfo) public committedBatches;
    /// @notice The mapping of batchNumber => bool
    mapping(bytes32 => bool) public commitedBatchStatus;
    /// @notice The mapping of batchNumber => bool
    mapping(bytes32 => bool) public finalizedBatchStatus;
    /// @notice The mapping of batchNumber => receiptRoot
    mapping(bytes32 => bytes32) public finalizedCombinedReceiptRoot;
    /// @notice Mapping of executed withdraw hash to a boolean value
    mapping(bytes32 => bool) public isWithdrawExecuted;

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyRoles(bytes32 role) {
        IRoleManager(roleManager).checkRole(role, _msgSender());
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of TwineChain.
    /// @param _messageQueue The address of `L1MessageQueue` contract.
    /// @param _verifier The address of zkevm verifier contract.
    function initialize(
        address _messageQueue,
        address _verifier,
        address _roleManager
    ) external initializer {
        messageQueue = _messageQueue;
        verifier = _verifier;
        roleManager = _roleManager;
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc ITwineChain
    function isBatchFinalized(
        bytes32 batchId
    ) public view override returns (bool) {
        return finalizedBatchStatus[batchId];
    }

    function isBatchCommitted(bytes32 batchId) public view returns (bool) {
        return commitedBatchStatus[batchId];
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc ITwineChain
    function setChainId(
        uint256 _chainId
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        chainId = _chainId;
    }

    /// @inheritdoc ITwineChain
    function setRoleManagerAddress(
        address _roleManagerAddress
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_roleManagerAddress == address(0)) {
            revert ErrorZeroAddress();
        }
        roleManager = _roleManagerAddress;
    }

    /// @inheritdoc ITwineChain
    function setMessengerQueueAddress(
        address _messageQueue
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_messageQueue == address(0)) {
            revert ErrorZeroAddress();
        }
        messageQueue = _messageQueue;
    }

    /// @inheritdoc ITwineChain
    function setVeriferAddress(
        address _verifier
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_verifier == address(0)) {
            revert ErrorZeroAddress();
        }
        verifier = _verifier;
    }

    /// @inheritdoc ITwineChain
    function setProgramVKey(
        bytes32 _executionVKey,
        bytes32 _inclusionVKey,
        bytes32 _withdrawalVKey
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        executionVKey = _executionVKey;
        inclusionVKey = _inclusionVKey;
        withdrawalVKey = _withdrawalVKey;

        emit setProgramVkey(_executionVKey, _inclusionVKey, _withdrawalVKey);
    }

    /// @inheritdoc ITwineChain
    function setGatewayAddress(
        address _ethGateway,
        address _ERC20Gateway
    ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        if (_ethGateway == address(0) || _ERC20Gateway == address(0)) {
            revert ErrorZeroAddress();
        }
        ethGateway = _ethGateway;
        ERC20Gateway = _ERC20Gateway;
    }

    function commitBatch(
        uint64 startBlock,
        uint64 endBlock,
        CommitBlockInfo[] memory commitBlockInfo
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        if (startBlock != 0) {
            require(
                startBlock == lastCommittedBlockNumber + 1,
                "Invalid start block"
            );
        }
        bytes32 batchId = getBatchId(startBlock, endBlock);
        uint256 expectedBlocks = endBlock - startBlock + 1;
        // Get the current count of blocks already committed for this batch.
        uint256 currentCount = commitedBlockInfo[batchId].length;
        require(
            currentCount + commitBlockInfo.length <= expectedBlocks,
            "Exceeds total expected blocks for this batch"
        );
        bytes32 previousBlockHash = currentCount == 0
            ? lastCommittedEndBlockHash
            : commitedBlockInfo[batchId][currentCount - 1].blockHash;

        uint256 len = commitBlockInfo.length;
        for (uint64 i; i < len; i++) {
            StoredBlockInfo memory blockInfo = StoredBlockInfo({
                previousHash: previousBlockHash,
                blockHash: commitBlockInfo[i].blockHash,
                transactionRoot: commitBlockInfo[i].transactionRoot,
                receiptRoot: commitBlockInfo[i].receiptRoot
            });
            previousBlockHash = commitBlockInfo[i].blockHash;
            commitedBlockInfo[batchId].push(blockInfo);
        }

        if (commitedBlockInfo[batchId].length == expectedBlocks) {
            lastCommittedEndBlockHash = previousBlockHash;
            bytes32 batchHash = _calculateBatchHash(batchId);
            StoredBatchInfo memory batchInfo = StoredBatchInfo({
                startBlock: startBlock,
                endBlock: endBlock,
                batchHash: batchHash
            });
            committedBatches[batchId] = batchInfo;
            lastCommittedBlockNumber = endBlock;
            commitedBatchStatus[batchId] = true;
            finalizedCombinedReceiptRoot[batchId] = getCombinedReceiptRoot(
                startBlock,
                endBlock
            );
            emit CommitBatch(
                batchInfo.startBlock,
                batchInfo.endBlock,
                block.number,
                batchId,
                batchInfo.batchHash
            );
        }
    }

    function FinalizeBatch(
        bytes memory publicInputForExecution,
        bytes memory executionProof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        StoredBatchInfo memory batchInfo = _decodeBatchInfo(
            publicInputForExecution
        );
        bytes32 batchId = getBatchId(batchInfo.startBlock, batchInfo.endBlock);
        require(
            batchInfo.batchHash == committedBatches[batchId].batchHash,
            "Batch hash should be same"
        );
        SP1Verifier(verifier).verifyProof(
            executionVKey,
            publicInputForExecution,
            executionProof
        );
        lastFinalizedBlockNumber = batchInfo.endBlock;
        finalizedBatchStatus[batchId] = true;

        emit FinalizedBatch(
            batchInfo.startBlock,
            batchInfo.endBlock,
            block.number,
            batchId,
            batchInfo.batchHash
        );
    }

    /// @inheritdoc ITwineChain
    function commitAndFinalizeTransactions(
        bytes memory transactionInfo,
        bytes memory inclusionProof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        // Decode the first 40 bytes for transaction info
        bytes memory transactionDataBytes = new bytes(48);
        for (uint256 i = 0; i < 48; i++) {
            transactionDataBytes[i] = transactionInfo[i];
        }
        TransactionInfo memory transaction_data = _decodeTransactionInfo(
            transactionDataBytes
        );

        require(
            lastCommittedBlockNumber >= transaction_data.endBlock,
            "The required block has not yet been committed"
        );
        bytes32 batchId = getBatchId(
            transaction_data.startBlock,
            transaction_data.endBlock
        );

        require(
            isBatchFinalized(batchId),
            "Batch needs to be finalized first."
        );

        transaction_data.receiptRoot = finalizedCombinedReceiptRoot[batchId];

        // Decode the next 120 bytes for transaction information for ethererum
        bytes memory chainDataBytes = new bytes(120);
        for (uint256 i = 0; i < 120; i++) {
            chainDataBytes[i] = transactionInfo[40 + i];
        }

        ChainCommitment memory chain_data = _decodeChainCommitment(
            chainDataBytes
        );

        require(
            chain_data.depositCount <=
                IL1MessageQueue(messageQueue)
                    .nextCrossDomainDepositMessageIndex(),
            "Invalid deposit count"
        );
        require(
            chain_data.withdrawCount <=
                IL1MessageQueue(messageQueue)
                    .nextCrossDomainWithdrawalMessageIndex(),
            "Invalid withdraw count"
        );

        //  Calculating deposit and withdraw rolling hash from the data in queue
        uint64 depositCount = chain_data.depositCount;
        bytes32 depositRollingHash = _calculateRollingHash(
            TransactionType.deposit,
            depositCount
        );

        require(
            depositRollingHash == chain_data.depositRollingHash,
            "calculated depositRollingHash is not equal with transaction info"
        );

        uint64 withdrawCount = chain_data.withdrawCount;
        bytes32 withdrawRollingHash = _calculateRollingHash(
            TransactionType.withdraw,
            withdrawCount
        );

        require(
            withdrawRollingHash == chain_data.withdrawRollingHash,
            "calculated withdrawRollingHash is not equal with transaction info"
        );

        uint64 lzTransactionCount = chain_data.lzTransactionCount;
        bytes32 lzTransactionRollingHash = _calculateRollingHash(
            TransactionType.layerZero,
            lzTransactionCount
        );

        // Replacing the deposit and withdraw Rolling hash
        chain_data.depositRollingHash = depositRollingHash;
        chain_data.withdrawRollingHash = withdrawRollingHash;
        chain_data.lzTransactionRollingHash = lzTransactionRollingHash;

        bytes
            memory publicInputForInclusion = _calculatePublicInputForInclusion(
                transactionInfo,
                chain_data
            );

        bytes memory inclusionProofWithSelector = prependBytes(inclusionProof);

        SP1Verifier(verifier).verifyProof(
            inclusionVKey,
            publicInputForInclusion,
            inclusionProofWithSelector
        );

        // Move the withdrawal that are ready for execution to execution queue
        for (uint256 i = 0; i < depositCount; i++) {
            IL1MessageQueue.MessageData memory forced_message = IL1MessageQueue(
                messageQueue
            ).getCrossDomainWithdrawalMessage(i);

            IL1MessageQueue(messageQueue).appendExecutionMessage(
                forced_message.nonce,
                forced_message.chainId,
                forced_message.blockNumber,
                forced_message.l1Token,
                forced_message.l2Token,
                forced_message.fromAddress,
                forced_message.toAddress,
                forced_message.amount
            );
        }

        // remove deposits, and withdrawals  messages from queue
        IL1MessageQueue(messageQueue).popFirstNDepositElement(depositCount);
        IL1MessageQueue(messageQueue).popFirstNWithdrawalElement(withdrawCount);
        emit FinalizedTransaction(
            transaction_data.startBlock,
            transaction_data.endBlock,
            block.number,
            batchId
        );
    }

    function finalizeWithdrawal(
        FinalizeWithdrawalInput memory withdrawalInputs
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        require(
            isBatchFinalized(withdrawalInputs.publicInput.batchId),
            "Batch needs to be finalized first."
        );

        require(
            finalizedCombinedReceiptRoot[
                withdrawalInputs.publicInput.batchId
            ] == withdrawalInputs.publicInput.receiptRoot,
            "Receipt roots must be equal."
        );

        if (withdrawalInputs.publicInput.isForced == 1) {
            require(
                IL1MessageQueue(messageQueue).isNonceInExecutionQueue(
                    withdrawalInputs.publicInput.nonce
                ) == true,
                "Nonce not present in execution message buffer"
            );
        }

        bytes memory replacedPublicInput = abi.encodePacked(
            withdrawalInputs.publicInput.chainId,
            withdrawalInputs.publicInput.batchId,
            withdrawalInputs.publicInput.nonce,
            withdrawalInputs.publicInput.isForced,
            withdrawalInputs.publicInput.receiptRoot,
            withdrawalInputs.publicInput.l1ReceiverAddress,
            withdrawalInputs.publicInput.l1TokenAddress,
            withdrawalInputs.publicInput.l2TokenAddress,
            withdrawalInputs.publicInput.amount
        );
        require(
            !isWithdrawExecuted[keccak256(replacedPublicInput)],
            "Withdrawal already executed"
        );
        // bytes memory withdrawalProofWithSelector = prependBytes(
        //     withdrawalInputs.inclusionProof
        // );

        // SP1Verifier(verifier).verifyProof(
        //     withdrawalVKey,
        //     replacedPublicInput,
        //     withdrawalProofWithSelector
        // );

        if (
            withdrawalInputs.publicInput.l1TokenAddress.stringToAddress() ==
            address(0)
        ) {
            IL1ETHGateway(ethGateway).finalizeTokenWithdrawal(
                withdrawalInputs.publicInput.l1TokenAddress,
                withdrawalInputs.publicInput.l2TokenAddress,
                withdrawalInputs.publicInput.l1ReceiverAddress,
                withdrawalInputs.publicInput.amount
            );
        } else {
            // ERC20 withdrawal
            IL1ERC20Gateway(ERC20Gateway).finalizeTokenWithdrawal(
                withdrawalInputs.publicInput.l1TokenAddress,
                withdrawalInputs.publicInput.l2TokenAddress,
                withdrawalInputs.publicInput.l1ReceiverAddress,
                withdrawalInputs.publicInput.amount
            );
        }

        if (withdrawalInputs.publicInput.isForced == 1) {
            IL1MessageQueue(messageQueue).removeExecutionMessage(
                withdrawalInputs.publicInput.nonce
            );
        }

        isWithdrawExecuted[keccak256(replacedPublicInput)] = true;
    }

    /**********************
     * Internal Functions *
     **********************/

    function _decodeTransactionInfo(
        bytes memory transactionDataBytes
    ) internal pure returns (TransactionInfo memory) {
        uint64 startBlock;
        uint64 endBlock;
        bytes32 receiptRoot;

        assembly {
            startBlock := mload(add(transactionDataBytes, 8))
            endBlock := mload(add(transactionDataBytes, 16))
            receiptRoot := mload(add(transactionDataBytes, 48))
        }

        return
            TransactionInfo({
                startBlock: startBlock,
                endBlock: endBlock,
                receiptRoot: receiptRoot
            });
    }

    function _decodeChainCommitment(
        bytes memory chainCommitment
    ) internal pure returns (ChainCommitment memory) {
        uint64 depositCount;
        bytes32 depositRollingHash;
        uint64 withdrawCount;
        bytes32 withdrawRollingHash;
        uint64 lzTransactionCount;
        bytes32 lzTransactionRollingHash;

        assembly {
            depositCount := mload(add(chainCommitment, 8))
            depositRollingHash := mload(add(chainCommitment, 40))
            withdrawCount := mload(add(chainCommitment, 48))
            withdrawRollingHash := mload(add(chainCommitment, 80))
            lzTransactionCount := mload(add(chainCommitment, 88))
            lzTransactionRollingHash := mload(add(chainCommitment, 120))
        }

        return
            ChainCommitment({
                depositCount: depositCount,
                depositRollingHash: depositRollingHash,
                withdrawCount: withdrawCount,
                withdrawRollingHash: withdrawRollingHash,
                lzTransactionCount: lzTransactionCount,
                lzTransactionRollingHash: lzTransactionRollingHash
            });
    }

    function _decodeBatchInfo(
        bytes memory batchPublicValues
    ) internal pure returns (StoredBatchInfo memory) {
        uint64 startBlock;
        uint64 endBlock;
        bytes32 batchHash;

        assembly {
            startBlock := mload(add(batchPublicValues, 8))
            endBlock := mload(add(batchPublicValues, 16))
            batchHash := mload(add(batchPublicValues, 48))
        }

        return
            StoredBatchInfo({
                startBlock: startBlock,
                endBlock: endBlock,
                batchHash: batchHash
            });
    }

    function _calculateBatchHash(
        bytes32 batchId
    ) internal view returns (bytes32) {
        bytes memory calculatedBatchHash;
        StoredBlockInfo[] memory blockInfo = commitedBlockInfo[batchId];
        uint256 len = blockInfo.length;
        for (uint256 i = 0; i < len; i++) {
            calculatedBatchHash = abi.encodePacked(
                calculatedBatchHash,
                abi.encodePacked(
                    blockInfo[i].previousHash,
                    blockInfo[i].blockHash,
                    blockInfo[i].transactionRoot,
                    blockInfo[i].receiptRoot
                )
            );
        }
        return keccak256(calculatedBatchHash);
    }

    function _calculateRollingHash(
        TransactionType transaction_type,
        uint64 count
    ) internal view returns (bytes32) {
        bytes memory calculatedRollingHash;
        IL1MessageQueue.MessageData[]
            memory selectedMessages = new IL1MessageQueue.MessageData[](count);

        if (transaction_type == TransactionType.deposit) {
            for (uint64 i = 0; i < count; i++) {
                selectedMessages[i] = IL1MessageQueue(messageQueue)
                    .getCrossDomainDepositMessage(i);
            }
        } else if (transaction_type == TransactionType.withdraw) {
            for (uint64 i = 0; i < count; i++) {
                selectedMessages[i] = IL1MessageQueue(messageQueue)
                    .getCrossDomainWithdrawalMessage(i);
            }
        } else {
            for (uint64 i = 0; i < count; i++) {
                selectedMessages[i] = IL1MessageQueue(messageQueue)
                    .getCrossDomainLayerZeroMessage(i);
            }
        }
        uint256 len = selectedMessages.length;
        for (uint64 i = 0; i < len; i++) {
            calculatedRollingHash = abi.encodePacked(
                calculatedRollingHash,
                abi.encodePacked(
                    selectedMessages[i].nonce,
                    selectedMessages[i].chainId,
                    selectedMessages[i].blockNumber,
                    selectedMessages[i].fromAddress,
                    selectedMessages[i].toAddress,
                    selectedMessages[i].l1Token,
                    selectedMessages[i].l2Token,
                    selectedMessages[i].amount
                )
            );
        }
        return keccak256(calculatedRollingHash);
    }

    function prependBytes(
        bytes memory originalData
    ) public view returns (bytes memory) {
        bytes4 prefix = bytes4(SP1Verifier(verifier).VERIFIER_HASH());

        bytes memory result = new bytes(prefix.length + originalData.length);

        for (uint256 i = 0; i < prefix.length; i++) {
            result[i] = prefix[i];
        }
        for (uint256 i = 0; i < originalData.length; i++) {
            result[i + prefix.length] = originalData[i];
        }
        return result;
    }

    function getBatchId(
        uint64 _startBlock,
        uint64 _endBlock
    ) internal pure returns (bytes32) {
        bytes memory batchId = abi.encodePacked(_startBlock, _endBlock);
        return keccak256(batchId);
    }

    function getCombinedReceiptRoot(
        uint64 _startBlock,
        uint64 _endBlock
    ) internal view returns (bytes32) {
        bytes32 batchId = getBatchId(_startBlock, _endBlock);
        bytes memory combinedReceiptRoot;
        StoredBlockInfo[] memory blockInfo = commitedBlockInfo[batchId];
        uint256 len = blockInfo.length;
        for (uint256 i; i < len; i++) {
            combinedReceiptRoot = abi.encodePacked(
                combinedReceiptRoot,
                abi.encodePacked(blockInfo[i].receiptRoot)
            );
        }

        return keccak256(combinedReceiptRoot);
    }

    function _calculatePublicInputForInclusion(
        bytes memory transaction_info,
        ChainCommitment memory chain_data
    ) internal pure returns (bytes memory) {
        bytes memory prefix = slice(transaction_info, 0, 40);
        bytes memory suffix = slice(
            transaction_info,
            160,
            transaction_info.length - 160
        );

        bytes memory replacement = abi.encodePacked(
            chain_data.depositCount,
            chain_data.depositRollingHash,
            chain_data.withdrawCount,
            chain_data.withdrawRollingHash,
            chain_data.lzTransactionCount,
            chain_data.lzTransactionRollingHash
        );

        // Concatenate prefix + chain_data + suffix
        return abi.encodePacked(prefix, replacement, suffix);
    }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(data.length >= start + length, "Invalid slice range");

        bytes memory result = new bytes(length);

        assembly {
            // Get the pointer to the result's data
            let resultPtr := add(result, 0x20)
            // Get the pointer to the start position in the input data
            let dataPtr := add(add(data, 0x20), start)

            // Copy the data
            for {
                let i := 0
            } lt(i, length) {
                i := add(i, 0x20)
            } {
                mstore(add(resultPtr, i), mload(add(dataPtr, i)))
            }
        }

        return result;
    }
}
