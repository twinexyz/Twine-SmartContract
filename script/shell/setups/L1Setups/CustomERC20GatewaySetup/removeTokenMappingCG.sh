#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "L1 Token Address: " L1_TOKEN_ADDRESS

#export env variables:
export PRIVATE_KEY
export L1_TOKEN_ADDRESS


#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1CustomERC20GatewaySetup.s.sol:RemoveTokenMapping \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "L1_TOKEN_ADDRESS=$L1_TOKEN_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"