#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"


# Prompt for commitment data
read -p "Batch Number: " BATCH_NUMBER
read -p "Batch Hash: " BATCH_HASH
read -p "Previous State Root: " PREVIOUS_STATE_ROOT
read -p "State Root: " STATE_ROOT
read -p "Transaction Root: " TRANSACTION_ROOT
read -p "Receipt Root: " RECEIPT_ROOT
read -p "Execution Proof: " EXECUTION_PROOF

# export env variables:
export PRIVATE_KEY
export BATCH_NUMBER
export BATCH_HASH
export PREVIOUS_STATE_ROOT
export STATE_ROOT
export TRANSACTION_ROOT
export RECEIPT_ROOT
export EXECUTION_PROOF
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:CommitAndFinalizeBatch \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "BATCH_NUMBER=$BATCH_NUMBER" --env "BATCH_HASH=$BATCH_HASH" --env "PREVIOUS_STATE_ROOT=$PREVIOUS_STATE_ROOT" \
    --env "STATE_ROOT=$STATE_ROOT" --env "TRANSACTION_ROOT=$TRANSACTION_ROOT" --env "RECEIPT_ROOT=$RECEIPT_ROOT" \
    --env "EXECUTION_PROOF=$EXECUTION_PROOF"  --env "PRIVATE_KEY=$PRIVATE_KEY"
