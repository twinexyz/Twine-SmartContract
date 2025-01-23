#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"


#prompt the user
read -p "Token Addresses (comma-separated): " TOKENS
read -p "Gateway Addresses (comma-separated): " GATEWAYS

#export env variables:
export PRIVATE_KEY
export TOKENS
export GATEWAYS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1GatewayRouterSetup.s.sol:SetERC20Gateway \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "TOKENS=$TOKENS" --env "GATEWAYS=$GATEWAYS" --env "PRIVATE_KEY=$PRIVATE_KEY"
