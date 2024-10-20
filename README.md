# Omni Travia Game

A Travia Game built on Omni, playable on any Omni-supported chain.

## How it works

The protocol has two contracts

- [`TraviaGuesser`](./src/TraviaGuesser.sol)
- [`TraviaHost`](./src/TraviaHost.sol)

The first accepts submitting answers. The second maintains global leaderboard, and tracks each player's progress.


## Testing

This example includes example solidity [tests](./test) . They make use of Omni's `MockPortal` utility to test cross chain interactions.

Run tests with

```bash
make test
```

## Try it out

To try out the contracts, you can deploy them to a local Omni devnet.

```bash
# Deploy testnet and contracts
make all
source deployments.sh

# Mint some test token for the player
make mint-op-token
make approve-op-token

# Add as many questions as you want
OWNER_PK=0x... QUESTION="Question 1" ANSWER="Answer 1" make add-question

# Player now can get the question
make get-player-question
# Submit an answer
ANSWER="Answer 1" make get-answer-fee
ANSWER="Answer 1" FEE=xxxx make submit-player-answer

# Player can get the leaderboard or progress
make get-leaderboard
make get-player-progress
```
