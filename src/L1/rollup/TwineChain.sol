// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ITwineChain} from "./ITwineChain.sol";
import {IL1MessageQueue} from "./IL1MessageQueue.sol";

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";


/// @title TwineChain
/// @notice This contract maintains the data for Meta Rollup.
contract TwineChain is ITwineChain {
    /**********
     * Errors *
     **********/

    error ErrorZeroAddress();

    /// @dev Thrown when the given account is not EOA account.
    error ErrorAccountIsNotEOA();

    /// @dev Thrown when committing a committed batch.
    error ErrorBatchIsAlreadyCommitted();

    /// @dev Thrown when finalizing a verified batch.
    error ErrorBatchIsAlreadyVerified();

    /// @dev Thrown when committing empty batch (batch without chunks)
    error ErrorBatchIsEmpty();


    /// @notice The chain id of the corresponding layer 2 chain.
    uint64 public immutable layer2ChainId;

    /// @notice The address of L1MessageQueue contract.
    address public immutable messageQueue;

    /// @notice The address of RollupVerifier.
    address public immutable verifier;

    /// @inheritdoc ITwineChain
    uint256 public override lastFinalizedBatchIndex;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override committedBatches;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override finalizedStateRoots;

    /// @inheritdoc ITwineChain
    mapping(uint256 => bytes32) public override withdrawRoots;

    /***************
     * Constructor *
     ***************/

    /// @notice Constructor for `ScrollChain` implementation contract.
    ///
    /// @param _chainId The chain id of L2.
    /// @param _messageQueue The address of `L1MessageQueue` contract.
    /// @param _verifier The address of zkevm verifier contract.


    constructor(
        uint64 _chainId,
        address _messageQueue,
        address _verifier
    ) {
        if (_messageQueue == address(0) || verifier == address(0)) {
            revert ErrorZeroAddress();
        }
        layer2ChainId = _chainId;
        messageQueue = _messageQueue;
        verifier = _verifier;
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @inheritdoc ITwineChain
    function isBatchFinalized(uint256 _batchIndex) external view override returns (bool) {
        return _batchIndex <= lastFinalizedBatchIndex;
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

     /// @inheritdoc ITwineChain
     function commitBatch(
        bytes calldata _parentBatchHeader, 
        bytes[] memory _chunks,
        bytes calldata _skippedL1MessageBitmap
    ) external override {
        (bytes32 _parentBatchHash, uint256 _batchIndex, uint256 _totalL1MessagePoppedOverall) = _beforeCommitBatch(
            _parentBatchHeader, 
            _chunks
        );

        bytes32 _batchHash;
        uint256 batchPtr;
        bytes32 _dataHash;
        uint256 _totalL1MessagePoppedInBatch;
        (_dataHash, _totalL1MessagePoppedInBatch) = _commitChunks(
            _totalL1MessagePoppedOverall,
            _chunks,
            _skippedL1MessageBitmap
        );
        assembly {
            batchPtr := mload(0x40)
            _totalL1MessagePoppedOverall := add(_totalL1MessagePoppedOverall, _totalL1MessagePoppedInBatch)
        }

        storeBatchIndex(batchPtr, _batchIndex);
        storeL1MessagePopped(batchPtr, _totalL1MessagePoppedInBatch);
        storeTotalL1MessagePopped(batchPtr, _totalL1MessagePoppedOverall);
        storeDataHash(batchPtr, _dataHash);
        storeParentBatchHash(batchPtr, _parentBatchHash);
        storeSkippedBitmap(batchPtr, _skippedL1MessageBitmap);
    }

    function _beforeCommitBatch(bytes calldata _parentBatchHeader, bytes[] memory _chunks)
        private
        view
        returns (
            bytes32 _parentBatchHash,
            uint256 _batchIndex,
            uint256 _totalL1MessagesPoppedOverall
        )
    {
        // checks whether the batch is empty
        if (_chunks.length == 0) revert ErrorBatchIsEmpty();
        (, _parentBatchHash, _batchIndex, _totalL1MessagesPoppedOverall) = _loadBatchHeader(_parentBatchHeader);
        unchecked {
            _batchIndex += 1;
        }
        if (committedBatches[_batchIndex] != 0) revert ErrorBatchIsAlreadyCommitted();
    }

    function _loadBatchHeader(bytes calldata _batchHeader)
        internal
        view
        virtual
        returns (
            uint256 batchPtr,
            bytes32 _batchHash,
            uint256 _batchIndex,
            uint256 _totalL1MessagePoppedOverall
        )
    {
        uint256 _length;
        (batchPtr, _length) = _loadAndValidate(_batchHeader);

        _batchHash = computeBatchHash(batchPtr, _length);
        _batchIndex = getBatchIndex(batchPtr);
        _totalL1MessagePoppedOverall = getTotalL1MessagePopped(batchPtr);
    }
     
    function _loadAndValidate(bytes calldata _batchHeader) internal pure returns (uint256 batchPtr, uint256 length) {
        length = _batchHeader.length;
        
        //copy batch header to memory.
        assembly {
            batchPtr := mload(0x40)
            calldatacopy(batchPtr, _batchHeader.offset, length)
            mstore(0x40, add(batchPtr, length))
        }
    }

    function computeBatchHash(uint256 batchPtr, uint256 length) internal pure returns (bytes32 _batchHash) {
        assembly {
            _batchHash := keccak256(batchPtr, length)
        }
    }

    function getBatchIndex(uint256 batchPtr) internal pure returns (uint256 _batchIndex) {
        assembly {
            _batchIndex := shr(192, mload(add(batchPtr, 0)))
        }
    }

    function getTotalL1MessagePopped(uint256 batchPtr) internal pure returns (uint256 _totalL1MessagePopped) {
        assembly {
            _totalL1MessagePopped := shr(192, mload(add(batchPtr, 17)))
        }
    }


    function storeBatchIndex(uint256 batchPtr, uint256 _batchIndex) internal pure {
        assembly {
            mstore(add(batchPtr, 1), shl(192, _batchIndex))
        }
    }

}

