#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Default values
DEFAULT_RECEIVER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_AMOUNT="2000000000000000000" # 2 ETH in wei
DEFAULT_DATA="0x"

#prompt the user
read -p "Receiver address (default: $DEFAULT_RECEIVER): " RECEIVER
RECEIVER=${RECEIVER:-$DEFAULT_RECEIVER}

read -p "Deposit amount in wei (default: $DEFAULT_AMOUNT): " DEPOSIT_AMOUNT
DEPOSIT_AMOUNT=${DEPOSIT_AMOUNT:-$DEFAULT_AMOUNT}

read -p "Bytes of Data (default: $DEFAULT_DATA): " DATA
DATA=${DATA:-$DEFAULT_DATA}

# export env variables:
export RECEIVER
export DEPOSIT_AMOUNT
export DATA
export PRIVATE_KEY
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:DepositETH \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "RECEIVER=$RECEIVER" --env "DEPOSIT_AMOUNT=$DEPOSIT_AMOUNT" \
    --env "DATA=$DATA" --env "PRIVATE_KEY=$PRIVATE_KEY" 
