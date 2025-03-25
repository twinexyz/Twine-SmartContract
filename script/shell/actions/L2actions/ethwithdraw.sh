#!/bin/bash

# Default values
DEFAULT_RECEIVER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_AMOUNT="1000000000000000000" # 1 ETH in wei
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"

# prompt the user
read -p "L1 token: " L1_TOKEN

read -p "Receiver address on L1 (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Withdraw amount in wei (default: $DEFAULT_AMOUNT): " AMOUNT
AMOUNT=${AMOUNT:-$DEFAULT_AMOUNT}

read -p "Chain ID: " CHAIN_ID


# export env variables:
export RECEIVER
export AMOUNT
export PRIVATE_KEY
export CHAIN_ID
export L2_TOKEN
export L1_TOKEN
 
#Run the forge script with the provided default values
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:WithdrawETH \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "RECEIVER=$RECEIVER" --env "AMOUNT=$AMOUNT" --env "CHAIN_ID=$CHAIN_ID" --env "PRIVATE_KEY=$PRIVATE_KEY" \
    --env "L2_TOKEN=$L2_TOKEN" --env "L1_TOKEN=$L1_TOKEN"
