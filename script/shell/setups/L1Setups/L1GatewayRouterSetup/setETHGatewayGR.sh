#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "L1 ETHGateway Address: " ETH_GATEWAY_ADDRESS

#export env variables:
export L1_PRIVATE_KEY
export ETH_GATEWAY_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1GatewayRouterSetup.s.sol:SetETHGateway \
    --fork-url "$L1_DEFAULT_FORK_URL"   \
    --broadcast