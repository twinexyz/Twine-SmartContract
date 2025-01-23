// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SP1Verifier} from "@sp1-contracts/v4.0.0-rc.3/SP1VerifierGroth16.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {Types} from "../../libraries/rlp/Types.sol";
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

    /// @notice The verification key for execution proof.
    bytes32 public executionVKey;

    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

    /// @notice The address of RollupVerifier.
    address public verifier;

    /// @notice Address of the rolemanager contract
    address roleManager;

    /// @notice The Number of Last Batch Committed
    uint256 public override lastCommittedBatchNumber;

    /// @notice The Number of Last Batch Finalized
    uint256 public override lastFinalizedBatchNumber;

    /// @notice The verification key for inclusion proof
    bytes32 public inclusionVKey;

    /// @notice The verification key for withdrawal proof
    bytes32 public withdrawalVKey;

    //gateway address of eth
    address public ethGateway;

    //gateway address of erc20 gateway
    address public ERC20Gateway;

    /*************
     * Mappings  *
     *************/

    /// @notice The mapping of batchNumber => CommittedBatches
    mapping(uint256 => StoredBatchInfo) public committedBatches;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;

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
        uint256 _batchNumber
    ) public view override returns (bool) {
        return _batchNumber <= lastFinalizedBatchNumber;
    }

    function isBatchCommitted(uint256 _batchNumber) public view returns (bool) {
        return _batchNumber <= lastCommittedBatchNumber;
    }

    function getReceiptRoot(
        uint256 _batchNumber
    ) public view returns (bytes32) {
        require(isBatchCommitted(_batchNumber), "Batch Needs to be commited");
        return committedBatches[_batchNumber].receiptRoot;
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

    /// @inheritdoc ITwineChain
    function commitAndFinalizeBatch(
        StoredBatchInfo memory commit_info,
        bytes memory execution_proof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        // Commit the batch only if the pervious batch is finalized properly
        require(
            commit_info.batchNumber == lastFinalizedBatchNumber + 1,
            "Invalid Batch Sequence"
        );

        require(
            commit_info.previousStateRoot ==
                committedBatches[commit_info.batchNumber].previousStateRoot,
            "Invalid Batch Sequence"
        );

        require(
            isBatchFinalized(commit_info.batchNumber - 1),
            "Previous batch must be finalized."
        );

        // Verify Execution Proof
        bytes memory publicInputForExecution = abi.encodePacked(
            commit_info.batchNumber,
            commit_info.batchHash,
            commit_info.previousStateRoot,
            commit_info.stateRoot,
            commit_info.transactionRoot,
            commit_info.receiptRoot
        );

        bytes memory executionProofWithSelector = prependBytes(execution_proof);

        SP1Verifier(verifier).verifyProof(
            executionVKey,
            publicInputForExecution,
            executionProofWithSelector
        );

        committedBatches[commit_info.batchNumber] = commit_info;
        finalizedStateRoots[commit_info.batchNumber] = commit_info.stateRoot;
        lastCommittedBatchNumber = commit_info.batchNumber;
        lastFinalizedBatchNumber = commit_info.batchNumber;
    }

    /// @inheritdoc ITwineChain
    function commitAndFinalizeTransactions(
        bytes memory transaction_info,
        bytes memory inclusion_proof
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        // Decode the first 40 bytes for transaction info
        bytes memory transactionDataBytes = new bytes(40);
        for (uint256 i = 0; i < 40; i++) {
            transactionDataBytes[i] = transaction_info[i];
        }
        TransactionInfo memory transaction_data = _decodeTransactionInfo(
            transactionDataBytes
        );

        require(
            isBatchFinalized(transaction_data.batchNumber),
            "Batch needs to be finalized first."
        );
        require(
            transaction_data.transactionRoot ==
                committedBatches[transaction_data.batchNumber].transactionRoot,
            "Invalid transaction data"
        );

        // Decode the next 120 bytes for transaction information for ethererum
        bytes memory chainDataBytes = new bytes(120);
        for (uint256 i = 0; i < 120; i++) {
            chainDataBytes[i] = transaction_info[40 + i];
        }

        ChainCommitment memory chain_data = _decodeChainCommitment(
            chainDataBytes
        );

        require(
            chain_data.depositCount <
                IL1MessageQueue(messageQueue)
                    .nextCrossDomainDepositMessageIndex(),
            "Invalid deposit count"
        );

        require(
            chain_data.withdrawCount <
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

        uint64 withdrawCount = chain_data.withdrawCount;
        bytes32 withdrawRollingHash = _calculateRollingHash(
            TransactionType.withdraw,
            withdrawCount
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
                transaction_info,
                chain_data
            );

        bytes memory inclusionProofWithSelector = prependBytes(inclusion_proof);

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

        // remove deposits, withdrawals and layerZero messages from queue
        IL1MessageQueue(messageQueue).popFirstNDepositElement(depositCount);
        IL1MessageQueue(messageQueue).popFirstNWithdrawalElement(withdrawCount);
        IL1MessageQueue(messageQueue).popFirstNLayerZeroElement(
            lzTransactionCount
        );
    }

    function finalizeWithdrawal(
        FinalizeWithdrawalInput memory withdrawalInputs
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        require(
            isBatchFinalized(withdrawalInputs.publicInput.batchNumber),
            "Batch needs to be finalized first."
        );

        StoredBatchInfo memory committedTransaction = committedBatches[
            withdrawalInputs.publicInput.batchNumber
        ];

        withdrawalInputs.publicInput.receiptRoot = committedTransaction
            .receiptRoot;

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
            withdrawalInputs.publicInput.batchNumber,
            withdrawalInputs.publicInput.nonce,
            withdrawalInputs.publicInput.isForced,
            withdrawalInputs.publicInput.receiptRoot,
            withdrawalInputs.publicInput.l1ReceiverAddress,
            withdrawalInputs.publicInput.l1TokenAddress,
            withdrawalInputs.publicInput.l2TokenAddress,
            withdrawalInputs.publicInput.amount
        );
        bytes memory withdrawalProofWithSelector = prependBytes(
            withdrawalInputs.inclusionProof
        );

        SP1Verifier(verifier).verifyProof(
            withdrawalVKey,
            replacedPublicInput,
            withdrawalProofWithSelector
        );

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
    }

    /**********************
     * Internal Functions *
     **********************/

    function _decodeTransactionInfo(
        bytes memory transactionDataBytes
    ) internal pure returns (TransactionInfo memory) {
        uint64 batchNumber;
        bytes32 transactionRoot;

        assembly {
            batchNumber := mload(add(transactionDataBytes, 8))
            transactionRoot := mload(add(transactionDataBytes, 40))
        }

        return
            TransactionInfo({
                batchNumber: batchNumber,
                transactionRoot: transactionRoot
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

        for (uint64 i = 0; i < selectedMessages.length; i++) {
            calculatedRollingHash = abi.encodePacked(
                calculatedRollingHash,
                abi.encodePacked(
                    selectedMessages[i].nonce,
                    selectedMessages[i].chainId,
                    selectedMessages[i].blockNumber,
                    selectedMessages[i].toAddress,
                    selectedMessages[i].l1Token,
                    selectedMessages[i].l2Token,
                    selectedMessages[i].amount
                )
            );
        }
        bytes32 hashedRollingHash = keccak256(calculatedRollingHash);
        return hashedRollingHash;
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

    function _calculatePublicInputForInclusion(
        bytes memory transaction_info,
        ChainCommitment memory chain_data
    ) internal returns (bytes memory) {
        bytes memory prefix = slice(transaction_info, 0, 40); // First 40 bytes
        bytes memory suffix = slice(
            transaction_info,
            160,
            transaction_info.length - 160
        ); // After 160 bytes

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
