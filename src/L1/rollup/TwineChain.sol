// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

contract TwineChain is ITwineChain {
    /// @notice The address of the SP1 verifier contract.
    /// @dev This can either be a specific SP1Verifier for a specific version, or the
    ///      SP1VerifierGateway which can be used to verify proofs for any version of SP1.
    ///      For the list of supported verifiers on each chain, see:
    ///      https://github.com/succinctlabs/sp1-contracts/tree/main/contracts/deployments
    address public verifier;

    /// @notice The verification key.
    bytes32 public TwineChainVKey;


    /// @inheritdoc IExecutor
    function commitBatches(
        StoredBatchInfo memory _lastCommittedBatchData,
        CommitBatchInfo[] calldata _newBatchesData
    ) external nonReentrant onlyValidator {
        _commitBatches(_lastCommittedBatchData, _newBatchesData);
    }

    function _commitBatches(
        StoredBatchInfo memory _lastCommittedBatchData,
        CommitBatchInfo[] calldata _newBatchesData
    ) internal {
        for(uint256 i = 0; i < _newBatchesData.length; i = i.uncheckedInc()) {
            _lastCommittedBatchData = _commitOneBatch(_lastCommittedBatchData, _newBatchesData[i]);

            emit BlockCommit(
                _lastCommittedBatchData.batchNumber,
                _lastCommittedBatchData.batchHash
            );
        }
    }

    function _commmitOneBatch(
        StoredBatchInfo memory _previousBatch,
        CommitBatchInfo calldata _newBatch
    ) internal view returns (StoredBatchInfo memory) {
        require(_newBatch.batchNumber == _previousBatch.batchNumber + 1, "f"); // only commit next batch

        return StoredBatchInfo({
            batchNumber: _newBatch.batchNumber,
            batchHash: _newBatch.newStateRoot,
            numberOfLayer1Txs: _newBatch.numberOfLayer1Txs,
            priorityOperationHash: _newBatch.priorityOperationHash,
            l2logsTreeRoot: logOut,
            timestamp: _newBatch.timestamp
        });

    }

}