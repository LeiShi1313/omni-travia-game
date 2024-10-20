// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {TriviaGuesser} from "src/TriviaGuesser.sol";
import {TriviaHost} from "src/TriviaHost.sol";
import {TestToken} from "./utils/TestToken.sol";
import {MockPortal} from "omni/core/test/utils/MockPortal.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {GasLimits} from "src/GasLimits.sol";
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
        uint256 fee = guesser.answerFee(answer);

        // give user some tokens
        token.mint(user, balance);

        // approve the guesser to spend them
        vm.prank(user);
        token.approve(address(guesser), balance);

        // requires fee
        vm.expectRevert("XApp: insufficient funds");
        vm.prank(user);
        guesser.submitAnswer(answer);

        // charges fee to user
        vm.deal(address(guesser), fee);
        vm.expectRevert("TriviaGuesser: insufficient fee");
        vm.prank(user);
        guesser.submitAnswer(answer);

        // expect xcall to host
        vm.expectCall(
            address(portal),
            abi.encodeCall(
                MockPortal.xcall,
                (
                    portal.omniChainId(),
                    ConfLevel.Finalized,
                    address(host),
                    abi.encodeCall(TriviaHost.submitAnswer, (user, answer)),
                    GasLimits.SubmitAnswer
                )
            )
        );
        vm.prank(user);
        vm.deal(user, fee);
        guesser.submitAnswer{value: fee}(answer);
    }
}
