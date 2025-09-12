#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Default values
DEFAULT_RECEIVER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_AMOUNT="1000000000000000000"

#prompt the user
read -p "Token: " TOKEN

read -p "Receiver address on L1 (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Withdraw amount (default: $DEFAULT_AMOUNT): " AMOUNT
AMOUNT=${AMOUNT:-$DEFAULT_AMOUNT}

read -p "Chain ID: " CHAIN_ID

# export env variables:
export PRIVATE_KEY
export TOKEN
export RECEIVER
export AMOUNT
export CHAIN_ID
 
#Run the forge script with the provided default values
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:WithdrawERC20 \
    --fork-url "$L2_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "RECEIVER=$RECEIVER" --env "AMOUNT=$AMOUNT" --env "PRIVATE_KEY=$PRIVATE_KEY" \
    --env "CHAIN_ID=$CHAIN_ID" --env "TOKEN=$TOKEN"
