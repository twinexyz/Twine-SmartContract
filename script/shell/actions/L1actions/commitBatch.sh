#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"

# Prompt user for start and end blocks
read -p "Start Block: " START_BLOCK
read -p "End Block: " END_BLOCK

# export env variables:
export START_BLOCK
export END_BLOCK
export PRIVATE_KEY

# Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:CommitBatch \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "START_BLOCK=$START_BLOCK" --env "END_BLOCK=$END_BLOCK" --env "PRIVATE_KEY=$PRIVATE_KEY"

