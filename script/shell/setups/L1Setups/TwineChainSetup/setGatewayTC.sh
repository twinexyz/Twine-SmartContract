#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "ETH Gateway: " ETH_GATEWAY
read -p "ERC20 Gateway: " ERC20_GATEWAY

#export env variables:
export L1_PRIVATE_KEY
export ETH_GATEWAY
export ERC20_GATEWAY


#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/TwineChainSetup.s.sol:SetGatewayAddress \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 