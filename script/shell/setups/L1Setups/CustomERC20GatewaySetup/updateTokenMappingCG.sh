#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"


#prompt the user
read -p "L1 Token Address: " L1_TOKEN_ADDRESS
read -p "L2 Token Address: " L2_TOKEN_ADDRESS

#export env variables:
export PRIVATE_KEY
export L1_TOKEN_ADDRESS
export L2_TOKEN_ADDRESS


#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1CustomERC20GatewaySetup.s.sol:UpdateTokenMapping \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "L1_TOKEN_ADDRESS=$L1_TOKEN_ADDRESS" --env "L2_TOKEN_ADDRESS=$L2_TOKEN_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
