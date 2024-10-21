ifneq ("$(wildcard .env)","")
	include .env
	export $(shell sed 's/=.*//' .env)
endif

help:  ## Display this help message
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'

ensure-deps:
	@which omni > /dev/null 2>&1 || { \
		echo "Binary `omni` not found. Installing..."; \
		curl -sSfL https://raw.githubusercontent.com/omni-network/omni/main/scripts/install_omni_cli.sh | sh -s; \
	}

build:
	forge build

clean:
	forge clean

test:
	forge test -vvv

devnet-start:
	omni devnet start

devnet-clean:
	omni devnet clean

devnet-deploy:
	./script/devnet-deploy.sh

add-question:
	forge script AddQuestion \
    --broadcast \
    --rpc-url $(OMNI_RPC) \
    --private-key $(OWNER_PK) \
    --sig $$(cast calldata "run(address,string,string,uint256)" $(HOST) "$(QUESTION)" "$(ANSWER)" "$(REWARD)")

get-leaderboard:
	cast call $(HOST) "getLeaderboard()(address[])" \
		--rpc-url $(OMNI_RPC) \
		--private-key $(PLAYER_PK)

get-player-question:
	cast call $(HOST) "getPlayerQuestion(address)(string)" $(PLAYER_ACCOUNT) \
		--rpc-url $(OMNI_RPC) \
		--private-key $(PLAYER_PK)

get-player-progress:
	cast call $(HOST) "getPlayerProgress(address)(uint256)" $(PLAYER_ACCOUNT) \
		--rpc-url $(OMNI_RPC) \
		--private-key $(PLAYER_PK)

get-player-reward:
	cast call $(HOST) "getPlayerReward(address)(uint256)" $(PLAYER_ACCOUNT) \
		--rpc-url $(OMNI_RPC) \
		--private-key $(PLAYER_PK)

get-reward-fee:
	cast call $(HOST) "rewardFee(address,uint64)(uint256)" $(PLAYER_ACCOUNT) $(OP_CHAINID) \
		--rpc-url $(OMNI_RPC) \
		--private-key $(PLAYER_PK)

get-reward:
	cast send $(OP_GUESSER) "reward(uint64)" $(OP_CHAINID) \
		--rpc-url $(OMNI_RPC) \
		--value $(FEE) \
		--private-key $(PLAYER_PK)

get-answer-hash:
	forge script GetAnswerHash \
		--rpc-url $(OMNI_RPC) \
		--private-key $(PLAYER_PK) \
		--sig $$(cast calldata "run(string)" "$(ANSWER)")

get-answer-fee:
	cast call $(OP_GUESSER) "answerFee(bytes32)(uint256)" $(ANSWER_HASH) \
		--rpc-url $(OP_RPC) \
		--private-key $(PLAYER_PK)

submit-player-answer:
	cast send $(OP_GUESSER) "submitAnswer(bytes32)" $(ANSWER_HASH) \
		--rpc-url $(OP_RPC) \
		--value $(FEE) \
		--private-key $(PLAYER_PK)

mint-op-token:
	cast send $(OP_TOKEN) "mint(address,uint256)" $(DEV_ACCOUNT) 100 \
		--rpc-url $(OMNI_RPC) \
		--private-key $(DEV_PK)

approve-op-token:
	cast send $(OP_TOKEN) "approve(address,uint256)" $(OP_GUESSER) 100 \
		--rpc-url $(OMNI_RPC) \
		--private-key $(DEV_PK)

all: devnet-clean devnet-start devnet-deploy

.PHONY: ensure-deps build clean test devnet-start devnet-clean deploy bootstrap
