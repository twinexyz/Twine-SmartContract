#!/bin/bash

# Default values
DEFAULT_RECEIVER="0x000000000000000000000000000000000000dead"
DEFAULT_AMOUNT="1000000000000000000" # 1 ETH in wei
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"

#prompt the user
read -p "Enter receiver address (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Enter deposit amount in wei (default: $DEFAULT_AMOUNT): " DEPOSIT_AMOUNT
DEPOSIT_AMOUNT=${DEPOSIT_AMOUNT:-$DEFAULT_AMOUNT}

read -p "Enter fork URL (default: $DEFAULT_FORK_URL): " FORK_URL
FORK_URL=${FORK_URL:-$DEFAULT_FORK_URL}

#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:DepositETH \
    --fork-url $FORK_URL  \
    --broadcast \
    -- --env "RECEIVER=$RECEIVER" --env "DEPOSIT_AMOUNT=$DEPOSIT_AMOUNT" --env "PRIVATE_KEY=$PRIVATE_KEY"
