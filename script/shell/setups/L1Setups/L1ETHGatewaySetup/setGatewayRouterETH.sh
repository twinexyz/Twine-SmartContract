#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Gateway Router: " GATEWAY_ROUTER_ADDRESS

#export env variables:
export PRIVATE_KEY
export GATEWAY_ROUTER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/ETHGatewaySetup.s.sol:setGatewayRouter \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "GATEWAY_ROUTER_ADDRESS=$GATEWAY_ROUTER_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
