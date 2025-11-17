#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

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
export L1_PRIVATE_KEY
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
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 
