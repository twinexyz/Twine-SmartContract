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
read -p "Receiver address (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Withdraw amount (default: $DEFAULT_AMOUNT): " DEPOSIT_AMOUNT
WITHDRAW_AMOUNT=${DEPOSIT_AMOUNT:-$DEFAULT_AMOUNT}

# export env variables:
export RECEIVER
export WITHDRAW_AMOUNT
export PRIVATE_KEY
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:ForcedWithdrawERC20 \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "RECEIVER=$RECEIVER" --env "DEPOSIT_AMOUNT=$WITHDRAW_AMOUNT" --env "PRIVATE_KEY=$PRIVATE_KEY"
