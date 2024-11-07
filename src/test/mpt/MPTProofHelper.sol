// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;
import "src/libraries/mpt/MerklePatriciaProofVerifier.sol";

contract MPTProofHelper {
    function verifyRLPProof(bytes memory rlpProof, bytes32 rootHash, bytes memory mptKey)
        public
        pure
        returns (bytes memory value)
    {
        return MerklePatriciaProofVerifier.verifyRLPProof(rlpProof, rootHash, mptKey);
    }

    function verify(RLPReader.RLPItem[] memory proof, bytes32 rootHash, bytes memory mptKeyNibbles)
        public
        pure
        returns (bytes memory value)
    {
        return MerklePatriciaProofVerifier.verify(proof, rootHash, mptKeyNibbles);
    }

    function decodeNibbles(bytes memory bz, uint256 offset) public pure returns (bytes memory) {
        return MerklePatriciaProofVerifier.decodeNibbles(bz, offset);
    }
}
