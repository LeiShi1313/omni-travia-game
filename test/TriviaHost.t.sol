// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {TriviaGuesser} from "src/TriviaGuesser.sol";
import {TriviaHost} from "src/TriviaHost.sol";
import {TestToken} from "./utils/TestToken.sol";
import {MockPortal} from "omni/core/test/utils/MockPortal.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {GasLimits} from "src/GasLimits.sol";
import {Answer} from "src/utils/Answer.sol";
import {Test} from "forge-std/Test.sol";

/**
 * @title TriviaHost_Test
 * @notice Test suite for TriviaHost
 */
contract TriviaHost_Test is Test {
    TestToken token;
    MockPortal portal;
    TriviaHost host;
    address owner;

    address guesser1;
    address guesser2;

    uint64 chainId1 = 1;
    uint64 chainId2 = 2;

    function setUp() public {
        owner = makeAddr("owner");
        guesser1 = makeAddr("guesser1");
        guesser2 = makeAddr("guesser2");

        token = new TestToken();
        portal = new MockPortal();
        host = new TriviaHost(address(portal), owner);
    }

    /**
     * @notice Test TriviaHost.submitAnswer
     */
    function test_submitAnswer() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        // only xcall
        vm.expectRevert("TriviaHost: only xcall");
        host.submitAnswer(user1, Answer.encodeAnswer(user1, "answer"));

        // only supported chain
        vm.expectRevert("TriviaHost: unsupported chain");
        portal.mockXCall({
            sourceChainId: chainId1, // not registered yet
            sender: address(1234),
            to: address(host),
            data: abi.encodeCall(TriviaHost.submitAnswer, (user1, Answer.encodeAnswer(user1, "answer"))),
            gasLimit: GasLimits.SubmitAnswer
        });

        // only known guesser
        vm.prank(owner);
        host.registerGuesser(chainId1, guesser1);

        vm.expectRevert("TriviaHost: only guesser");
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: address(1234), // not guesser1
            to: address(host),
            data: abi.encodeCall(TriviaHost.submitAnswer, (user1, Answer.encodeAnswer(user1, "answer"))),
            gasLimit: GasLimits.SubmitAnswer
        });

        vm.prank(owner);
        host.addQuestion("question", keccak256("answer"));

        vm.prank(user1);
        assertEq(host.getPlayerQuestion(user1), "question");

        // submit wrong answer
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: guesser1,
            to: address(host),
            data: abi.encodeCall(TriviaHost.submitAnswer, (user1, Answer.encodeAnswer(user1, "wrong answer"))),
            gasLimit: GasLimits.SubmitAnswer
        });

        // assert progress
        assertEq(host.getPlayerProgress(user1), 0);
        assertEq(host.getPlayerQuestion(user1), "question");

        // submit correct answer
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: guesser1,
            to: address(host),
            data: abi.encodeCall(TriviaHost.submitAnswer, (user1, Answer.encodeAnswer(user1, "answer"))),
            gasLimit: GasLimits.SubmitAnswer
        });

        // assert progress
        assertEq(host.getPlayerProgress(user1), 1);
        assertEq(host.getLeaderboard()[0], user1);
        vm.expectRevert("TriviaHost: all questions answered");
        vm.prank(user1);
        host.getPlayerQuestion(user1);

        vm.prank(owner);
        host.addQuestion("question2", keccak256("answer2"));

        // user2 answers all questions
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: guesser1,
            to: address(host),
            data: abi.encodeCall(TriviaHost.submitAnswer, (user2, Answer.encodeAnswer(user2, "answer"))),
            gasLimit: GasLimits.SubmitAnswer
        });
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: guesser1,
            to: address(host),
            data: abi.encodeCall(TriviaHost.submitAnswer, (user2, Answer.encodeAnswer(user2, "answer2"))),
            gasLimit: GasLimits.SubmitAnswer
        });

        // user2 should also be on the leaderboard
        assertEq(host.getPlayerProgress(user2), 2);
        assertEq(host.getLeaderboard()[0], user1);
        assertEq(host.getLeaderboard()[1], user2);
    }
}
