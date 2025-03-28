#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"


# Prompt for commitment data
read -p "Chain ID: " CHAIN_ID
read -p "Block Number: (Of Twine) " BLOCK_NUMBER
read -p "Nonce: " NONCE
read -p "Is Forced: " IS_FORCED
read -p "Receipt Root: " RECEIPT_ROOT
read -p "L1 Receiver Address: " L1_RECEIVER_ADDRESS
read -p "L1 Token Address: " L1_TOKEN_ADDRESS
read -p "L2 Token Address: " L2_TOKEN_ADDRESS
read -p "Amount: " AMOUNT
read -p "Inclusion Proof: " INCLUSION_PROOF

# export env variables:
export PRIVATE_KEY
export CHAIN_ID
export BLOCK_NUMBER
export NONCE
export IS_FORCED
export RECEIPT_ROOT
export L1_RECEIVER_ADDRESS
export L1_TOKEN_ADDRESS
export L2_TOKEN_ADDRESS
export AMOUNT
export INCLUSION_PROOF
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:finalizeWithdrawal \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "CHAIN_ID=$CHAIN_ID" --env "BATCH_NUMBER=$BLOCK_NUMBER" --env "NONCE=$NONCE" --env "IS_FORCED=$IS_FORCED" \
    --env "RECEIPT_ROOT=$RECEIPT_ROOT" --env "L1_RECEIVER_ADDRESS=$L1_RECEIVER_ADDRESS" --env "L1_TOKEN_ADDRESS=$L1_TOKEN_ADDRESS" \
    --env "L2_TOKEN_ADDRESS=$L2_TOKEN_ADDRESS" --env "AMOUNT=$AMOUNT"  --env "PRIVATE_KEY=$PRIVATE_KEY" \
    --env "INCLUSION_PROOF=$INCLUSION_PROOF"
