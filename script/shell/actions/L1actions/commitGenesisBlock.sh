#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Prompt user for Genesis Block Hash
read -p "Genesis Block Hash: " GENESIS_BLOCK_HASH

# export env variables:
export GENESIS_BLOCK_HASH
export L1_PRIVATE_KEY

# Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:CommitGenesisBlock \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 