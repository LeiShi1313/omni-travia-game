#!/usr/bin/env bash
#
# Deploy contracts to Omni's devnet

set -e

# Private key for dev account 8, funded on devnet chains
deployer=0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
deployer_pk=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97

# Private key for dev account 9, funded on devnet chains
owner=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
owner_pk=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

player_account=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
player_pk=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Devnet info - portal address is same for all chains
devnet=$(omni devnet info)
portal=$(echo $devnet | jq -r '.[] | select(.chain_name == "omni_evm") | .portal_address')

# Get RPC URLs for each chain
rpcurl() {
  local chain=$1
  echo $(echo $devnet | jq -r ".[] | select(.chain_name == \"$chain\") | .rpc_url")
}

op_rpc=$(rpcurl mock_op)
arb_rpc=$(rpcurl mock_arb)
omni_rpc=$(rpcurl omni_evm)


# Get address of next contract to be deployed by deployer
getaddr() {
  local rpc=$1
  local prefix="Computed Address: " # Need to remove prefix from cast output
  echo $(cast compute-address $deployer --rpc-url $rpc | sed -e "s/^$prefix//")
}

# Deploys TestToken, return address
deploy_token() {
  local rpc=$1
  local token=$(getaddr $rpc)

  forge script DeployTestToken \
    --silent \
    --broadcast \
    --rpc-url $rpc \
    --private-key $deployer_pk

  if [ $? -ne 0 ]; then { exit 1; } fi

  echo $token
}

# Deploy TriviaGuesser, return address
deploy_guesser() {
  local rpc=$1
  local host=$2
  local token=$3

  # deploy guesser
  local guesser=$(getaddr $rpc)

  forge script DeployTriviaGuesser \
    --silent \
    --broadcast \
    --rpc-url $rpc \
    --private-key $deployer_pk \
    --sig $(cast calldata "run(address,address,address)" $portal $host $token)

  if [ $? -ne 0 ]; then { exit 1; } fi

  echo $guesser
}

# Deploy TriviaHost, return address
deploy_host() {
  local rpc=$1
  local host=$(getaddr $rpc)

  forge script DeployTriviaHost \
    --silent \
    --broadcast \
    --rpc-url $rpc \
    --private-key $deployer_pk \
    --sig $(cast calldata "run(address,address)" $owner $portal)

  if [ $? -ne 0 ]; then { exit 1; } fi

  echo $host
}

# Register guesser with host
register_guesser() {
  local rpc=$1
  local host=$2
  local chain_id=$3
  local guesser=$4

  forge script RegisterTriviaGuesser \
    --broadcast \
    --rpc-url $rpc \
    --private-key $owner_pk \
    --sig $(cast calldata "run(address,uint64,address)" $host $chain_id $guesser)
}

# Deploy tokens
op_token=$(deploy_token $op_rpc)
arb_token=$(deploy_token $arb_rpc)

# Deploy host
host=$(deploy_host $omni_rpc)

# Deploy guessers
op_guesser=$(deploy_guesser $op_rpc $host $op_token)
arb_guesser=$(deploy_guesser $arb_rpc $host $arb_token)

# Register guessers
register_guesser $omni_rpc $host $(cast chain-id --rpc-url $op_rpc) $op_guesser
register_guesser $omni_rpc $host $(cast chain-id --rpc-url $arb_rpc) $arb_guesser

echo "Portal: $portal"
echo "Token(op): $op_token"
echo "Token(arb): $arb_token"
echo "Guesser(op): $op_guesser"
echo "Guesser(arb): $arb_guesser"
echo "Host(omni): $host"

if test "$SHELL" = "/usr/bin/fish" -o "$SHELL" = "/bin/fish"; then
    echo "
set -x PORTAL $portal
set -x OP_TOKEN $op_token
set -x ARB_TOKEN $arb_token
set -x OP_GUESSER $op_guesser
set -x ARB_GUESSER $arb_guesser
set -x HOST $host
set -x OMNI_RPC $omni_rpc
set -x OP_RPC $op_rpc
set -x ARB_RPC $arb_rpc
set -x OP_CHAINID $(cast chain-id --rpc-url $op_rpc)
set -x ARB_CHAINID $(cast chain-id --rpc-url $arb_rpc)
set -x OMNI_CHAINID $(cast chain-id --rpc-url $omni_rpc)
set -x OWNER_ACCOUNT $owner
set -x OWNER_PK $owner_pk
set -x DEV_ACCOUNT $deployer
set -x DEV_PK $deployer_pk
set -x PLAYER_ACCOUNT $player_account
set -x PLAYER_PK $player_pk
" > deployments.fish

else
    echo "
PORTAL=$portal
OP_TOKEN=$op_token
ARB_TOKEN=$arb_token
OP_GUESSER=$op_guesser
ARB_GUESSER=$arb_guesser
HOST=$host
OMNI_RPC=$omni_rpc
OP_RPC=$op_rpc
ARB_RPC=$arb_rpc
OP_CHAINID=$(cast chain-id --rpc-url $op_rpc)
ARB_CHAINID=$(cast chain-id --rpc-url $arb_rpc)
OMNI_CHAINID=$(cast chain-id --rpc-url $omni_rpc)
OWNER_ACCOUNT=$owner
OWNER_PK=$owner_pk
DEV_ACCOUNT=$deployer
DEV_PK=$deployer_pk
PLAYER_ACCOUNT=$player_account
PLAYER_PK=$player_pk
" > deployments.sh
fi
