// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AppendOnlyMerkleTree} from "../../libraries/common/AppendOnlyMerkleTree.sol";

contract L2MessageQueue is AppendOnlyMerkleTree {
    
    /// @notice Emitted when a new message is added to the merkle tree.
    /// @param index The index of the corresponding message.
    /// @param messageHash The hash of the corresponding message.
    event AppendMessage(uint256 index, bytes32 messageHash);

    /// @notice The address of L2ScrollMessenger contract.
    address public messenger;

    function initialize(address _messenger) external {
        _initializeMerkleTree();
        messenger = _messenger;
    }

     /// @notice record the message to merkle tree and compute the new root.
    /// @param _messageHash The hash of the new added message.
    function appendMessage(bytes32 _messageHash) external returns (bytes32) {
        require(msg.sender == messenger, "only messenger");

        (uint256 _currentNonce, bytes32 _currentRoot) = _appendMessageHash(_messageHash);

        // We can use the event to compute the merkle tree locally.
        emit AppendMessage(_currentNonce, _messageHash);

        return _currentRoot;
    }
}