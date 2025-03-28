#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"


#prompt the user
read -p "Chain ID: " CHAIN_ID

#export env variables:
export PRIVATE_KEY
export CHAIN_ID

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/TwineChainSetup.s.sol:SetChainId \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "CHAIN_ID=$CHAIN_ID" --env "PRIVATE_KEY=$PRIVATE_KEY"
