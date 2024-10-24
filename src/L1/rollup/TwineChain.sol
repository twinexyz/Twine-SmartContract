// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ContextUpgradeable, ITwineChain {
    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();

    /// @notice The verification key.
    bytes32 public ProgramVKey;

    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

    /// @notice The address of RollupVerifier.
    address public verifier;

    /// @notice The index of Last Batch Committed
    uint256 public override lastCommittedBatchIndex;

    /// @notice The index of Last Batch Finalized
    uint256 public override lastFinalizedBatchIndex;

    /// @notice The mapping of batchIndex => CommittedBatches
    mapping(uint256 => StoredBatchInfo) public committedBatches;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;

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
    function initialize(address _messageQueue, address _verifier)
        external
        initializer
    {
        messageQueue = _messageQueue;
        verifier = _verifier;
    }

    function setAddress(address _messageQueue, address _verifier) external {
        messageQueue = _messageQueue;
        verifier = _verifier;
    }

    // To be only called by prover
    function setProgramVKey(bytes32 _programVKey) external {
        ProgramVKey = _programVKey;
    }

     /// @inheritdoc ITwineChain
    function commitBatch(CommitBatchInfo calldata _newBatchData) external {
        require(_newBatchData.batchNumber == lastCommittedBatchIndex + 1, "Only next batch can be committed.");
        StoredBatchInfo memory batchToCommit = _commitBatch(_newBatchData);
        committedBatches[batchToCommit.batchNumber] = batchToCommit;
        lastCommittedBatchIndex = batchToCommit.batchNumber;
    }

    function _commitBatch(CommitBatchInfo calldata _newBatchData) internal returns (StoredBatchInfo memory) {
        bytes memory proofInput = _calculateProofInput(_newBatchData);
        bytes32[] memory otherTransactionHash;
        bytes32[] memory withdrawalTransactionHash;

        bytes32 depositTransactionHash = keccak256(abi.encode(_newBatchData.depositTransactionObject));

        for(uint i = 0; i < _newBatchData.withdrawalTransactionObjects.length; i++) {
            withdrawalTransactionHash[i] = keccak256(abi.encode(_newBatchData.withdrawalTransactionObjects[i]));
        }

        for(uint j = 0; j < _newBatchData.otherTransactions.length; j++) {
            otherTransactionHash[j] = keccak256(abi.encode(_newBatchData.otherTransactions[j]));
        }

        return
            StoredBatchInfo({
                batchNumber: _newBatchData.batchNumber,
                stateRoot: _newBatchData.stateRoot,
                transactionRoot: _newBatchData.transactionRoot,
                depositTransactionHash: depositTransactionHash,
                withdrawalTransactionHashes: withdrawalTransactionHash,
                withdrawalStatus: _newBatchData.withdrawalStatus,
                otherTransactionHashes: otherTransactionHash,
                publicInput: proofInput
            });
    }

    function _calculateProofInput(CommitBatchInfo calldata _newBatchData)
        internal
        returns (bytes memory)
    {
        // // First we have to seperate out (L1 transaction object) and (L2 trasnactions + L1 transaction object of other L1s)
        // bytes32 L1transactions = _extractL1Transaction(_newBatchData.transactionList);
        // bytes32[] L2transactions = _extractL2Transaction(_newBatchData.transactionList);

        // // We need to calculate L1TransactionObject just like how relayer is calculating.
        // bytes32 L1transactionObject = _calculateTransactionObject(L1transactions);

        // // We will append (stateroot + l1txnobject + l2txns) and that is our public input
        // bytes inputs = _calculateProof(_newBatchData.newStateRoot, L1transactionObject, L2transactions);
        // return inputs;
        bytes memory inputs;
        return inputs;
    }

    /// @inheritdoc ITwineChain
    function finalizeBatch(uint256 batchNumber, bytes calldata _proofBytes) external {
        require(isBatchCommitted(batchNumber), "Batch Needs to be committed before finalization");

        bytes memory publicValues = committedBatches[batchNumber].publicInput;
        ISP1Verifier(verifier).verifyProof(ProgramVKey, publicValues, _proofBytes);

        finalizedStateRoots[batchNumber] = committedBatches[batchNumber].stateRoot;
        lastFinalizedBatchIndex = batchNumber;
    }  

    /// @inheritdoc ITwineChain
    function isBatchFinalized(uint256 _batchIndex)
        public
        view
        override
        returns (bool)
    {
        return _batchIndex <= lastFinalizedBatchIndex;
    }

    function isBatchCommitted(uint256 _batchIndex)
        public
        view
        returns (bool)
    {
        return _batchIndex <= lastCommittedBatchIndex;
    }



    /// @inheritdoc ITwineChain
    function inTransactionList(uint256 batchNumber, bytes32 transactionHash, bool _fromL1)
        external
        view
        returns (bool)
    {   
        bytes32[] memory transactions;
        // If the transaction is forcedInclusion, check in withdrawal transaction hash otherwise in other transaction hash
        if(_fromL1) {
            transactions = committedBatches[batchNumber].withdrawalTransactionHashes;
        } else {
            transactions = committedBatches[batchNumber].otherTransactionHashes;
        }

        for(uint256 i = 0; i < transactions.length; i++) {
            if(transactionHash == transactions[i]){
                return true;
            }
        }
        return false;
    }
}
