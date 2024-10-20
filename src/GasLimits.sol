// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

/**
 * @title GasLimits
 * @notice Constant gas limits used in xcalls.
 *         Values determined via unit tests, with buffer for safety.
 */
library GasLimits {
    /// @notice TriviaHost.submitAnswer xcall gas limit.
    uint64 internal constant SubmitAnswer = 5_000_000;

    /// @notice TriviaHost.getPlayerQuestion xcall gas limit.
    uint64 internal constant GetPlayerQuestion = 5_000_000;

    /// @notice TriviaGuesser.getPlayerProgress xcall gas limit.
    uint64 internal constant GetPlayerProgress = 5_000_000;
}
