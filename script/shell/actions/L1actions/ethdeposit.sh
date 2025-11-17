#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Default values
DEFAULT_RECEIVER="0xf423ea729de0f8f586628d762e8cc2fb873cc689"
DEFAULT_AMOUNT="1000000000000000000" # 2 ETH in wei
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
export L1_PRIVATE_KEY
 
#Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:DepositETH \
    --fork-url "$L1_DEFAULT_FORK_URL"  
