// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {TriviaHost} from "src/TriviaHost.sol";
import {Script} from "forge-std/Script.sol";

contract AddQuestion is Script {
    function run(address host, string memory question, string memory answer) public {
        vm.startBroadcast();
        bytes32 answerHash = keccak256(abi.encodePacked(answer));
        TriviaHost(host).addQuestion(question, answerHash);
        vm.stopBroadcast();
    }
}
