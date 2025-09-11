#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "L1 ETHGateway Address: " ETH_GATEWAY_ADDRESS

#export env variables:
export PRIVATE_KEY
export ETH_GATEWAY_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1GatewayRouterSetup.s.sol:SetETHGateway \
    --fork-url "$DEFAULT_FORK_URL"   \
    --broadcast \
    -- --env "ETH_GATEWAY_ADDRESS=$ETH_GATEWAY_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
