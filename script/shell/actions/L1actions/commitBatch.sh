#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"

# Prompt user for start and end blocks
read -p "Batch Number: " BATCH_NUMBER
read -p "Batch Hash: " BATCH_HASH

# export env variables:
export BATCH_NUMBER
export BATCH_HASH
export PRIVATE_KEY

# Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:CommitBatch \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "BATCH_NUMBER=$BATCH_NUMBER" --env "BATCH_HASH=$BATCH_HASH" --env "PRIVATE_KEY=$PRIVATE_KEY"

