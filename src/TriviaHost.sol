// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XApp} from "omni/core/src/pkg/XApp.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {GasLimits} from "./GasLimits.sol";
import {Answer} from "./utils/Answer.sol";
import {TriviaGuesser} from "./TriviaGuesser.sol";

/**
 * @title TriviaHost
 *
 * @notice The host of the game.
 */
contract TriviaHost is XApp, Ownable {
    struct Question {
        string question;
        bytes32 answerHash;
    }

    /// @notice Questions in the trivia game.
    Question[] private questions;

    /// Leaderboard of players in the trivia game.
    address[] private leaderboard;

    /// @notice Players in the trivia game.
    address[] private players;

    /// @notice Player progress.
    mapping(address => uint256) private playerProgress;

    /// @notice Address of trivia guesser each chain.
    mapping(uint256 => address) public triviaGusserOn;

    /// @notice Emitted when a question is added.
    event QuestionAdded(uint256 indexed questionId, string question);

    /// @notice Emitted when questionId is answered for the first time.
    event QuestionAnswered(address indexed player, uint256 indexed questionId);

    constructor(address portal, address owner) XApp(portal, ConfLevel.Finalized) Ownable(owner) {}

    /**
     * @notice Add a question to the game.
     * @param question Question to add.
     * @param answerHash Hash of the correct answer.
     */
    function addQuestion(string memory question, bytes32 answerHash) external onlyOwner {
        questions.push(Question({question: question, answerHash: answerHash}));
        emit QuestionAdded(questions.length - 1, question);
    }

    /**
     * @notice Get the question for a player.
     * @param player Player address.
     */
    function getPlayerQuestion(address player) external view returns (string memory) {
        require(questions.length > 0, "TriviaHost: no questions");

        uint256 playerQuestionId = playerProgress[player];
        require(playerQuestionId < questions.length, "TriviaHost: all questions answered");
        return questions[playerQuestionId].question;
    }

    function getPlayerProgress(address player) external view returns (uint256) {
        return playerProgress[player];
    }

    /**
     * @notice Record `amount` staked by `user` on `xmsg.sourceChainId`.
     *         Only callable via xcall by a known TriviaGuesser contract.
     * @param player   Account that answered.
     * @param answerHash   Hash of the answer.
     */
    function submitAnswer(address player, bytes32 answerHash) external xrecv {
        require(isXCall(), "TriviaHost: only xcall");
        require(triviaGusserOn[xmsg.sourceChainId] != address(0), "TriviaHost: unsupported chain");
        require(triviaGusserOn[xmsg.sourceChainId] == xmsg.sender, "TriviaHost: only guesser");

        uint256 playerQuestionId = playerProgress[player];
        require(playerQuestionId < questions.length, "TriviaHost: all questions answered");


        Question storage question = questions[playerQuestionId];
        bool isCorrect = Answer.verifyAnswer(player, question.answerHash, answerHash);
        if (isCorrect) {
            playerProgress[player]++;
            if (playerProgress[player] == 1) {
                players.push(player);
            }
            if (playerProgress[player] > leaderboard.length) {
                leaderboard.push(player);
                emit QuestionAnswered(player, playerQuestionId);
            }
        }
    }

    /**
     * @notice Get the leaderboard of players in the trivia game.
     */
    function getLeaderboard() external view returns (address[] memory) {
        return leaderboard;
    }

    /**
     * @notice Admin function to register a TriviaGuesser deployment.
     *         Deployments must be registered before they can be used.
     * @param chainId Chain ID of the TriviaGuesser deployment.
     * @param addr    Deployment address.
     */
    function registerGuesser(uint64 chainId, address addr) external onlyOwner {
        triviaGusserOn[chainId] = addr;
    }
}
