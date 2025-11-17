#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Default values
DEFAULT_RECEIVER="0xf423ea729de0f8f586628d762e8cc2fb873cc689"
DEFAULT_AMOUNT="1000000000000000000"

#prompt the user
read -p "Token: " TOKEN

read -p "Receiver address on L1 (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Withdraw amount (default: $DEFAULT_AMOUNT): " AMOUNT
AMOUNT=${AMOUNT:-$DEFAULT_AMOUNT}

read -p "Chain ID: " CHAIN_ID

# export env variables:
export L2_PRIVATE_KEY
export TOKEN
export RECEIVER
export AMOUNT
export CHAIN_ID
 
#Run the forge script with the provided default values
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:WithdrawERC20 \
    --fork-url "$L2_DEFAULT_FORK_URL"  \
    --broadcast 
