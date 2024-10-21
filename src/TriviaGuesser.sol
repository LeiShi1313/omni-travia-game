// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XApp} from "omni/core/src/pkg/XApp.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GasLimits} from "./GasLimits.sol";
import {TriviaHost} from "./TriviaHost.sol";
import {Answer} from "./utils/Answer.sol";

/**
 * @title TriviaGuesser
 *
 * @notice Deployed on multiple chains, this contract is the entry / exit point for
 *      our cross-chain game. It accepts submitting answers, and checks
 *      the answer with the TriviaHost on Omni. When a player first solves a question,
 *      a reward is paid out to them.
 */
contract TriviaGuesser is XApp {
    /// @notice Stake token.
    IERC20 public immutable token;

    /// @notice Address of the TriviaHost contract on omni.
    address public host;

    constructor(address portal_, address host_, address token_) XApp(portal_, ConfLevel.Finalized) {
        host = host_;
        token = IERC20(token_);
    }

    /**
     * @notice Submit an answer.
     * @param answerHash The result of hash(address, hash(answer)).
     */
    function submitAnswer(bytes32 answerHash) public payable {
        uint256 fee = xcall({
            destChainId: omniChainId(),
            to: host,
            data: abi.encodeCall(TriviaHost.submitAnswer, (msg.sender, answerHash)),
            gasLimit: GasLimits.SubmitAnswer
        });

        // Make sure the user paid
        require(msg.value >= fee, "TriviaGuesser: insufficient fee");
    }

    /**
     * @notice Returns the xcall fee for required to answer.
     */
    function answerFee(bytes32 answerHash) public view returns (uint256) {
        return feeFor({
            destChainId: omniChainId(),
            data: abi.encodeCall(TriviaHost.submitAnswer, (msg.sender, answerHash)),
            gasLimit: GasLimits.SubmitAnswer
        });
    }
}
