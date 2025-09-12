#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "L2 ETH Token: " L2_ETH_TOKEN_ADDRESS

#export env variables:
export PRIVATE_KEY
export L2_ETH_TOKEN_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/ETHGatewaySetup.s.sol:setL2TokenAddress \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "L2_ETH_TOKEN_ADDRESS=$L2_ETH_TOKEN_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
