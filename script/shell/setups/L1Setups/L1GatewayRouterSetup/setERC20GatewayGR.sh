#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Token Addresses (comma-separated): " TOKENS
read -p "Gateway Addresses (comma-separated): " GATEWAYS

#export env variables:
export PRIVATE_KEY
export TOKENS
export GATEWAYS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1GatewayRouterSetup.s.sol:SetERC20Gateway \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "TOKENS=$TOKENS" --env "GATEWAYS=$GATEWAYS" --env "PRIVATE_KEY=$PRIVATE_KEY"
