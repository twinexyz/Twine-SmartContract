#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Default values
DEFAULT_RECEIVER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_AMOUNT="1000000000000000000" # 1 ETH in wei


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
export L2_PRIVATE_KEY
export CHAIN_ID
export L2_TOKEN
export L1_TOKEN
 
#Run the forge script with the provided default values
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:WithdrawETH \
    --fork-url "$L2_DEFAULT_FORK_URL"  \
    --broadcast