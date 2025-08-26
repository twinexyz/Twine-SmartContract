#!/bin/bash

# Default values
DEFAULT_RECEIVER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_AMOUNT="2000000000000000000" # 2 ETH in wei
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"

#prompt the user
read -p "Receiver address (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Deposit amount in wei (default: $DEFAULT_AMOUNT): " DEPOSIT_AMOUNT
DEPOSIT_AMOUNT=${DEPOSIT_AMOUNT:-$DEFAULT_AMOUNT}

# export env variables:
export RECEIVER
export DEPOSIT_AMOUNT
export PRIVATE_KEY
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:DepositETH \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "RECEIVER=$RECEIVER" --env "DEPOSIT_AMOUNT=$DEPOSIT_AMOUNT" --env "PRIVATE_KEY=$PRIVATE_KEY"
