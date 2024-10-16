// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";


/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ITwineChain {

    /// @dev Thrown when the given address is `address(0)`.
    error ErrorZeroAddress();
    
    /// @notice The address of L1MessageQueue contract.
    address public immutable messageQueue;

    /// @notice The address of RollupVerifier.
    address public immutable verifier;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override committedBatches;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;

    struct StoredBatchInfo {
        uint64 batchNumber;
        bytes32[] transactionList;
        bytes32 stateRoot;
        bytes32 transactionRoot;
        bytes32 publicInput;
    }

    mapping (uint256 => StoredBatchInfo) public StoredBatch;

    struct CommitBatchInfo {
        uint64 batchNumber;
        bytes32[] transactionList;
        bytes32 newStateRoot;
        bytes32 transactionRoot;
    }

    StoredBatchInfo public lastBatchData;
    /***************
     * Constructor *
     ***************/

    /// @notice Constructor for `ScrollChain` implementation contract.
    ///
    /// @param _messageQueue The address of `L1MessageQueue` contract.
    /// @param _verifier The address of zkevm verifier contract.


    constructor(
        address _messageQueue,
        address _verifier
    ) {
        if (_messageQueue == address(0) || verifier == address(0)) {
            revert ErrorZeroAddress();
        }
        messageQueue = _messageQueue;
        verifier = _verifier;
    }

    function commitBatch(CommitBatchInfo calldata _newBatchData) external {
        lastBatchData = _commitBatch(_newBatchData);
        StoredBatch[lastBatchData.batchNumber] = lastBatchData;
    }

    function _commitBatch(CommitBatchInfo calldata _newBatchData) internal returns (StoredBatchInfo memory) {
        require(_newBatchData.batchNumber != lastBatchData.batchNumber + 1, "Only next batch can be committed.");
        bytes32 proofInput = _calculateProofInput(_newBatchData);
        return
            StoredBatchInfo({
                batchNumber: _newBatchData.batchNumber,
                transactionList: _newBatchData.transactionList,
                stateRoot: _newBatchData.stateRoot,
                transactionRoot: _newBatchData.transactionRoot,
                publicInput: proofInput
            });
    }

    function _calculateProofInput(CommitBatchInfo calldata _newBatchData) internal returns (bytes32) {

        // First we have to seperate out (L1 transaction object) and (L2 trasnactions + L1 transaction object of other L1s)
        bytes32 L1transaction = _extractL1Transaction(_newBatchData.transactionList);
        bytes32[] L2transactions = _extractL2Transaction(_newBatchData.transactionList);

        // We need to calculate L1TransactionObject just like how relayer is calculating.
        bytes32 L1transactionObject = _calculateTransactionObject(L1transactions);

        // We will append (stateroot + l1txnobject + l2txns) and that is our public input
        bytes32 inputs = _calculateProof(_newBatchData.newStateRoot, L1transactions, L2transactions);
        return inputs;
    }   
}