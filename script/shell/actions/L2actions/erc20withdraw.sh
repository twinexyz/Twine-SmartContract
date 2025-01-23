#!/bin/bash

# Default values
DEFAULT_AMOUNT="1000000000000000000"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"

#prompt the user
read -p "Token: " TOKEN

read -p "Receiver address: " RECEIVER

read -p "Withdraw amount (default: $DEFAULT_AMOUNT): " AMOUNT
DEPOSIT_AMOUNT=${DEPOSIT_AMOUNT:-$DEFAULT_AMOUNT}

read -p "Chain ID: " CHAIN_ID

# export env variables:
export RECEIVER
export AMOUNT
export PRIVATE_KEY
export TOKEN
export CHAIN_ID
 
#Run the forge script with the provided default values
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:WithdrawERC20 \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "RECEIVER=$RECEIVER" --env "DEPOSIT_AMOUNT=$DEPOSIT_AMOUNT" --env "PRIVATE_KEY=$PRIVATE_KEY"
