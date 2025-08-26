#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"

# Prompt user for start and end blocks
read -p "Batch Number: " BATCH_NUMBER
read -p "Public input: " PUBLIC_INPUT_FOR_EXECUTION
read -p "Execution Proof: " EXECUTION_PROOF

# export env variables:
export BATCH_NUMBER
export PUBLIC_INPUT_FOR_EXECUTION
export EXECUTION_PROOF
export PRIVATE_KEY

# Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:FinalizeBatch \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "BATCH_NUMBER=$BATCH_NUMBER" --env "PUBLIC_INPUT_FOR_EXECUTION=$PUBLIC_INPUT_FOR_EXECUTION" --env "EXECUTION_PROOF=$EXECUTION_PROOF" --env "PRIVATE_KEY=$PRIVATE_KEY"
