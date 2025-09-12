#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Chain Id: " CHAIN_ID

#export env variables:
export PRIVATE_KEY
export CHAIN_ID

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/MessageHandlerSetup.s.sol:SetChainId \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "CHAIN_ID=$CHAIN_ID" --env "PRIVATE_KEY=$PRIVATE_KEY"
