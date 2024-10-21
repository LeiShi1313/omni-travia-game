// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {TriviaGuesser} from "src/TriviaGuesser.sol";
import {Answer} from "src/utils/Answer.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract GetAnswerHash is Script {
    function run(string memory answer) public view {
        bytes32 answerHash = Answer.encodeAnswer(msg.sender, answer);
        console.logBytes32(answerHash);
    }
}
