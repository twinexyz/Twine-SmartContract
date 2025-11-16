#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

read -p "Chain Id to set: " CHAIN_ID

# export env variables:
export L1_PRIVATE_KEY
export CHAIN_ID

# Run the forge script
forge script script/setup/L1SetupScripts/ETHGatewaySetup.s.sol:SetChainId \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 