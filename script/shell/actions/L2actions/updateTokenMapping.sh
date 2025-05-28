#!/bin/bash

# Default values
PRIVATE_KEY="0x63ff47b31d047d471229d35e0e2b829708dde1f1e438bfaf1059d0de785dedc1"
DEFAULT_FORK_URL="https://rpc1.twine.limited/"


#prompt the user
read -p "ChainId of L1 TOKEN:" "CHAIN_ID"
read -p "L1 Token Address: " L1_TOKEN_ADDRESS
read -p "L2 Token Address: " L2_TOKEN_ADDRESS

#export env variables:
export PRIVATE_KEY
export CHAIN_ID
export L1_TOKEN_ADDRESS
export L2_TOKEN_ADDRESS

# Run the forge script
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:UpdateTokenMapping \
        --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "CHAIN_ID=$CHAIN_ID" --env "L1_TOKEN_ADDRESS=$L1_TOKEN_ADDRESS" --env "L2_TOKEN_ADDRESS=$L2_TOKEN_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"