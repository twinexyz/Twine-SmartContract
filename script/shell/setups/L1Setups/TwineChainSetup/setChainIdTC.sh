#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Chain ID: " CHAIN_ID

#export env variables:
export L1_PRIVATE_KEY
export CHAIN_ID

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/TwineChainSetup.s.sol:SetChainId \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast