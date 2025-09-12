#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "ChainId of L1 TOKEN:" "CHAIN_ID"
read -p "L2 Token Address: " L2_TOKEN_ADDRESS

#export env variables:
export PRIVATE_KEY
export CHAIN_ID
export L2_TOKEN_ADDRESS

# Run the forge script
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:RemoveTokenMapping \
    --fork-url "$L2_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "CHAIN_ID=$CHAIN_ID" --env "L2_TOKEN_ADDRESS=$L2_TOKEN_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"