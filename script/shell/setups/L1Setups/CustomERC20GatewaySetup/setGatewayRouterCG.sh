#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"


#prompt the user
read -p "Gateway Router Address: " GATEWAY_ROUTER_ADDRESS

#export env variables:
export PRIVATE_KEY
export GATEWAY_ROUTER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1CustomERC20GatewaySetup.s.sol:SetGatewayRouter \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "GATEWAY_ROUTER_ADDRESS=$GATEWAY_ROUTER_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
