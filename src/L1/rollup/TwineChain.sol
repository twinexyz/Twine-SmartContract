// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SP1Verifier} from "@sp1-contracts/v3.0.0/SP1VerifierGroth16.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {Types} from "../../libraries/rlp/Types.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";
import {ITwineDVN} from "../../lzdvn/interfaces/ITwineDVN.sol";
import {IRoleManager} from "../../libraries/access/IRoleManager.sol";

/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ContextUpgradeable, ITwineChain {

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

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

    /*************
     * Mappings  *
     *************/

    /// @notice The mapping of batchNumber => CommittedBatches
    mapping(uint256 => StoredBatchInfo) public committedBatches;
    
    /// @notice The mapping of batchNumber => TransactionInfo
    mapping(uint256 => TransactionInfo) public transactionDataStorage;

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
    function initialize(address _messageQueue, address _verifier,  address _roleManager) external initializer {
        messageQueue = _messageQueue;
        verifier = _verifier;
        roleManager = _roleManager;
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc ITwineChain
    function isBatchFinalized( uint256 _batchNumber) public view override returns (bool) {
        return _batchNumber <= lastFinalizedBatchNumber;
    }

    function isBatchCommitted(uint256 _batchNumber) public view returns (bool) {
        return _batchNumber <= lastCommittedBatchNumber;
    }

    function getReceiptRoot(uint256 _batchNumber) public view returns (bytes32) {
        require(isBatchCommitted(_batchNumber), "Batch Needs to be commited");
        return committedBatches[_batchNumber].receiptRoot;
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    function setChainId(uint256 _chainId) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        chainId = _chainId;
    }

    function setRoleManagerAddress(address _roleManagerAddress) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        roleManager = _roleManagerAddress;
    }

    function setMessengerQueueAddress( address _messageQueue) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        messageQueue = _messageQueue;
    }

    function setVeriferAddress( address _verifier ) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        verifier = _verifier;
    }

    function setProgramVKey( bytes32 _executionVKey, bytes32 _inclusionVKey, bytes32 _withdrawalVKey) external onlyRoles(IRoleManager(roleManager).CHAIN_ADMIN()) {
        executionVKey = _executionVKey;
        inclusionVKey = _inclusionVKey;
        withdrawalVKey = _withdrawalVKey;
    }


    /// @inheritdoc ITwineChain
    function commitBatch(
        StoredBatchInfo memory commit_info, 
        TransactionInfo memory transaction_info
    ) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {

        //require(isBatchFinalized(commit_info.batchNumber - 1), "Previous batch must be finalized.");
        require(commit_info.batchNumber == transaction_info.batchNumber, "Same batch data required.");

        // Calculating deposit and withdraw's rolling hash from the queue.
        uint64 depositCount = transaction_info.ethereum.deposit.depositCount;
        bytes32 depositRollingHash = _calculateRollingHash(true, depositCount);

        uint64 withdrawCount = transaction_info.ethereum.withdraw.withdrawCount;
        bytes32 withdrawRollingHash = _calculateRollingHash(false, withdrawCount);

        // Making Transaction info with replaced hashes
        transaction_info.ethereum.deposit.depositRollingHash = depositRollingHash;
        transaction_info.ethereum.withdraw.withdrawRollingHash = withdrawRollingHash;

        transactionDataStorage[transaction_info.batchNumber] = transaction_info;
        committedBatches[commit_info.batchNumber] = commit_info;
        lastCommittedBatchNumber = commit_info.batchNumber;
    }

    /// @inheritdoc ITwineChain
    function finalizeBatch(FinalizeInput calldata finalizeInput) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {
        
        require(
            isBatchCommitted(finalizeInput.batchNumber),
            "Batch needs to be committed before finalization"
        );
    
        // require(
        //     committedBatches[lastFinalizedBatchNumber].stateRoot == committedBatches[batchNumber].previousStateRoot,
        //     "Only next batch can be finalized."
        // );
 

        // Verify Execution Proof
        StoredBatchInfo memory committedBatch = committedBatches[finalizeInput.batchNumber];
        bytes memory executionPublicInput = abi.encodePacked(
            committedBatch.batchNumber,
            committedBatch.batchHash,
            committedBatch.previousStateRoot,
            committedBatch.stateRoot,
            committedBatch.transactionRoot,
            committedBatch.receiptRoot
        );
        bytes memory executionProofWithSelector = prependBytes(finalizeInput.executionProof);

        SP1Verifier(verifier).verifyProof( executionVKey, executionPublicInput, executionProofWithSelector);

        // Verify Inclusion Proof
        TransactionInfo memory committedTransaction = transactionDataStorage[finalizeInput.batchNumber];
        bytes memory inclusionPublicInput = _calculateInlusionInput(committedTransaction);
        bytes memory inclusionProofWithSelector = prependBytes(finalizeInput.inclusionProof);

        SP1Verifier(verifier).verifyProof( inclusionVKey, inclusionPublicInput, inclusionProofWithSelector);

        // Copy transactions with withdrawal status bit '1' into execution queue
        uint64 numberOfWithdrawals = committedTransaction.ethereum.withdraw.withdrawCount;
        string memory statusBit = committedTransaction.ethereum.withdraw.statusBit;

        bytes memory statusBytes = bytes(statusBit);  

        // Check if the count matches the length of string
        require(numberOfWithdrawals == statusBytes.length, "Status bit should be provided for individual withdrawals.");

        for(uint256 i = 0; i < statusBytes.length; i++) {
            require(statusBytes[i] == "0" || statusBytes[i] == "1", "Invalid status bit");
            if(statusBytes[i] == "1") {
                IL1MessageQueue.MessageData memory forced_message = IL1MessageQueue(messageQueue).getCrossDomainWithdrawalMessage(i);
                
                IL1MessageQueue(messageQueue).appendExecutionMessage(
                    forced_message.nonce,
                    forced_message.toAddress,
                    forced_message.l1Token,
                    forced_message.l2Token,
                    forced_message.chainId,
                    forced_message.amount,
                    forced_message.blockNumber
                );
            }
        }

        // remove deposits and withdrawals from queue
        uint64 numberOfDeposits = committedTransaction.ethereum.deposit.depositCount;

        IL1MessageQueue(messageQueue).popFirstNDepositElement(numberOfDeposits);
    
        IL1MessageQueue(messageQueue).popFirstNWithdrawalElement(numberOfWithdrawals);

        finalizedStateRoots[finalizeInput.batchNumber] = committedBatches[finalizeInput.batchNumber].stateRoot;

        lastFinalizedBatchNumber = finalizeInput.batchNumber;
    }

    function finalizeWithdrawal(FinalizeWithdrawalInput memory withdrawalInputs) external onlyRoles(IRoleManager(roleManager).TWINE_OPERATIONS_HANDLER()) {

        require(isBatchFinalized(withdrawalInputs.publicInput.batchNumber), "Batch needs to be finalized first.");

        TransactionInfo memory committedTransaction = transactionDataStorage[withdrawalInputs.publicInput.batchNumber];

        withdrawalInputs.publicInput.receiptRoot = committedTransaction.receiptRoot;

        bytes memory replacedPublicInput = abi.encodePacked(
            withdrawalInputs.publicInput.chainId,
            withdrawalInputs.publicInput.batchNumber,
            withdrawalInputs.publicInput.nonce,
            withdrawalInputs.publicInput.receiptRoot,
            withdrawalInputs.publicInput.l1ReceiverAddress,
            withdrawalInputs.publicInput.l1TokenAddress,
            withdrawalInputs.publicInput.amount
        );
        bytes memory withdrawalProofWithSelector = prependBytes(withdrawalInputs.inclusionProof);

        SP1Verifier(verifier).verifyProof( withdrawalVKey, replacedPublicInput, withdrawalProofWithSelector);

        IL1MessageQueue(messageQueue).appendExecutionMessage(
            withdrawalInputs.publicInput.nonce,
            withdrawalInputs.publicInput.l1ReceiverAddress, 
            withdrawalInputs.publicInput.l1TokenAddress,
            "", 
            withdrawalInputs.publicInput.chainId, 
            withdrawalInputs.publicInput.amount,
            0
        );
    } 

    /**********************
     * Internal Functions *
     **********************/

    function _calculateInlusionInput(TransactionInfo memory transaction) internal pure returns (bytes memory) {
        return abi.encodePacked(
            transaction.batchNumber,
            transaction.transactionRoot,
            transaction.receiptRoot,
            encodeChainCommitment(transaction.ethereum),
            encodeChainCommitment(transaction.solana)
        );
    }   

      function encodeChainCommitment(ChainCommitment memory chain) internal pure returns (bytes memory) {
        return abi.encodePacked(
            encodeDepositReturn(chain.deposit),
            encodeWithdrawReturn(chain.withdraw)
        );
    }

    function encodeDepositReturn(DepositReturn memory deposit) internal pure returns (bytes memory) {
        return abi.encodePacked(
            deposit.depositCount,
            deposit.depositRollingHash
        );
    }

    function encodeWithdrawReturn(WithdrawReturn memory withdraw) internal pure returns (bytes memory) {
        return abi.encodePacked(
            withdraw.withdrawCount,
            withdraw.withdrawRollingHash,
            withdraw.statusBit
        );
    }

    function _calculateRollingHash(bool isDeposit, uint64 count) internal view returns (bytes32) {
        bytes memory calculatedRollingHash;
        IL1MessageQueue.MessageData[] memory selectedMessages = new IL1MessageQueue.MessageData[](count);

        if(isDeposit) {
            for(uint64 i = 0; i< count; i++) {
                selectedMessages[i] = IL1MessageQueue(messageQueue).getCrossDomainDepositMessage(i);
            }
        } else {
            for(uint64 i = 0; i < count; i++) {
                selectedMessages[i] = IL1MessageQueue(messageQueue).getCrossDomainWithdrawalMessage(i);
            }
        }

        for(uint64 i = 0; i < selectedMessages.length; i++) {
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

    function prependBytes(bytes memory originalData ) public view returns (bytes memory) {
        
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

}
