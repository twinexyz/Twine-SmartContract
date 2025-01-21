#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"


# Prompt for commitment data
read -p "Transaction Info: " TRANSACTION_INFO
read -p "Inclusion Proof: " INCLUSION_PROOF


# export env variables:
export PRIVATE_KEY
export TRANSACTION_INFO
export INCLUSION_PROOF
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:commitAndFinalizeTransaction \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "TRANSACTION_INFO=$TRANSACTION_INFO" --env "INCLUSION_PROOF=$INCLUSION_PROOF" --env "PRIVATE_KEY=$PRIVATE_KEY"
