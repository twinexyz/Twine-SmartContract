#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

read -p "Chain Id to set: " CHAIN_ID

# export env variables:
export PRIVATE_KEY
export CHAIN_ID

# Run the forge script
forge script script/setup/L1SetupScripts/ETHGatewaySetup.s.sol:SetChainId \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
     -- --env "PRIVATE_KEY=$PRIVATE_KEY" --env "CHAIN_ID=$CHAIN_ID" 