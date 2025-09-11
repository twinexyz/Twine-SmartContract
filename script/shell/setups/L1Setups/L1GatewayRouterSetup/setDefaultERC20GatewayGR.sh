#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Default ERC20 Gateway Address: " CUSTOM_ERC20_GATEWAY_ADDRESS

#export env variables:
export PRIVATE_KEY
export CUSTOM_ERC20_GATEWAY_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1GatewayRouterSetup.s.sol:SetDefaultERC20Gateway \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "CUSTOM_ERC20_GATEWAY_ADDRESS=$CUSTOM_ERC20_GATEWAY_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
