#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Default ERC20 Gateway Address: " CUSTOM_ERC20_GATEWAY_ADDRESS

#export env variables:
export L1_PRIVATE_KEY
export CUSTOM_ERC20_GATEWAY_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1GatewayRouterSetup.s.sol:SetDefaultERC20Gateway \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 