// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

library Answer {
    function encodeAnswer(address player, string memory answer) internal pure returns (bytes32) {
        bytes32 answerHash = keccak256(abi.encodePacked(answer));
        return keccak256(abi.encodePacked(player, answerHash));
    }

    function verifyAnswer(address player, bytes32 answerHash, bytes32 submittedHash) internal pure returns (bool) {
        return keccak256(abi.encodePacked(player, answerHash)) == submittedHash;
    }
}
