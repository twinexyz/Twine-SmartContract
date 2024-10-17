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

    /// @notice The verification key.
    bytes32 public ProgramVKey;
    
    /// @notice The address of L1MessageQueue contract.
    address public messageQueue;

    /// @notice The address of RollupVerifier.
    address public verifier;

    /// @notice The index of Last Batch Finalized
    uint256 public override lastFinalizedBatchIndex;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override committedBatches;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;

    /// @notice Mapping of batchnumber => CommittedBatch
    mapping (uint256 => StoredBatchInfo) public CommittedBatch;

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

    // To be only called by prover
    function setProgramVKey(bytes32 _programVKey) external {
        ProgramVKey = _programVKey;
    }

    function commitBatch(CommitBatchInfo calldata _newBatchData) external {
        lastBatchData = _commitBatch(_newBatchData);
        CommittedBatch[lastBatchData.batchNumber] = lastBatchData;
    }

    function _commitBatch(CommitBatchInfo calldata _newBatchData) internal returns (StoredBatchInfo memory) {
        require(_newBatchData.batchNumber == lastBatchData.batchNumber + 1, "Only next batch can be committed.");
        bytes memory proofInput = _calculateProofInput(_newBatchData);
        return
            StoredBatchInfo({
                batchNumber: _newBatchData.batchNumber,
                transactionList: _newBatchData.transactionList,
                stateRoot: _newBatchData.newStateRoot,
                transactionRoot: _newBatchData.transactionRoot,
                publicInput: proofInput
            });
    }

    function _calculateProofInput(CommitBatchInfo calldata _newBatchData) internal returns (bytes memory) {

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

    function finalizeBatch(uint256 batchNumber, bytes calldata _proofBytes) external {
        bytes memory publicValues = CommittedBatch[batchNumber].publicInput;
        ISP1Verifier(verifier).verifyProof(ProgramVKey, publicValues, _proofBytes);


        finalizedStateRoots[batchNumber] = CommittedBatch[batchNumber].stateRoot;
        lastFinalizedBatchIndex = batchNumber;
    }  

    /// @inheritdoc ITwineChain
    function isBatchFinalized(uint256 _batchIndex) external view override returns (bool) {
        return _batchIndex <= lastFinalizedBatchIndex;
    }

    /// @inheritdoc ITwineChain
    function inTransactionList(uint256 batchNumber, bytes32 transactionHash) external view returns (bool) {
        bytes32[] memory transactions = CommittedBatch[batchNumber].transactionList;
        for(uint256 i = 0; i < transactions.length; i++) {
            if(transactionHash == transactions[i]){
                return true;
            }
        }
        return false;
    }

}
