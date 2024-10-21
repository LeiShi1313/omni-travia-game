// SPDX-License-Identifier: MIT
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
 * @title TriviaGuesser_Test
 * @notice Test suite for TriviaGuesser
 */
contract TriviaGuesser_Test is Test {
    TestToken token;
    MockPortal portal;
    TriviaGuesser guesser;
    address host;

    function setUp() public {
        host = makeAddr("host");
        token = new TestToken();
        portal = new MockPortal();
        guesser = new TriviaGuesser(address(portal), address(host), address(token));
    }

    /**
     * @notice Test TriviaGuesser.submitAnswer
     */
    function test_submitAnswer() public {
        address user = makeAddr("user");
        uint256 balance = 100 ether;
        string memory answer = "answer";
        bytes32 answerHash = Answer.encodeAnswer(user, answer);
        uint256 fee = guesser.answerFee(answerHash);

        // give user some tokens
        token.mint(user, balance);

        // approve the guesser to spend them
        vm.prank(user);
        token.approve(address(guesser), balance);

        // requires fee
        vm.expectRevert("XApp: insufficient funds");
        vm.prank(user);
        guesser.submitAnswer(answerHash);

        // charges fee to user
        vm.deal(address(guesser), fee);
        vm.expectRevert("TriviaGuesser: insufficient fee");
        vm.prank(user);
        guesser.submitAnswer(answerHash);

        // expect xcall to host
        vm.expectCall(
            address(portal),
            abi.encodeCall(
                MockPortal.xcall,
                (
                    portal.omniChainId(),
                    ConfLevel.Finalized,
                    address(host),
                    abi.encodeCall(TriviaHost.submitAnswer, (user, answerHash)),
                    GasLimits.SubmitAnswer
                )
            )
        );
        vm.prank(user);
        vm.deal(user, fee);
        guesser.submitAnswer{value: fee}(answerHash);
    }

    /**
     * @notice Test TriviaGuesser.sendReward
     */
    function test_sendReward() public {
        address user = makeAddr("user");
        uint256 amount = 10 ether;
        uint64 omniChainId = portal.omniChainId();
        token.mint(address(guesser), amount);

        // only xcall
        vm.expectRevert("TriviaGuesser: only xcall");
        guesser.sendReward(user, amount);

        // only omni
        vm.expectRevert("TriviaGuesser: only omni");
        portal.mockXCall({
            sourceChainId: 1234, // not omni chain id
            sender: address(host),
            to: address(guesser),
            data: abi.encodeCall(TriviaGuesser.sendReward, (user, amount)),
            gasLimit: GasLimits.SendReward
        });

        // only controller
        vm.expectRevert("TriviaGuesser: only host");
        portal.mockXCall({
            sourceChainId: omniChainId,
            sender: address(1234), // not controller
            to: address(guesser),
            data: abi.encodeCall(TriviaGuesser.sendReward, (user, amount)),
            gasLimit: GasLimits.SendReward
        });

        // withdraw
        portal.mockXCall({
            sourceChainId: portal.omniChainId(),
            sender: address(host),
            to: address(guesser),
            data: abi.encodeCall(TriviaGuesser.sendReward, (user, amount)),
            gasLimit: GasLimits.SendReward
        });

        // assert balances
        assertEq(token.balanceOf(address(guesser)), 0);
        assertEq(token.balanceOf(user), amount);
    }
}
