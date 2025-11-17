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
read -p "Receiver address (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Withdraw amount (default: $DEFAULT_AMOUNT): " DEPOSIT_AMOUNT
WITHDRAW_AMOUNT=${DEPOSIT_AMOUNT:-$DEFAULT_AMOUNT}

# export env variables:
export RECEIVER
export WITHDRAW_AMOUNT
export L1_PRIVATE_KEY
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:ForcedWithdrawERC20 \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 