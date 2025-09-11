#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "L1 Token Address: " L1_TOKEN_ADDRESS
read -p "L2 Token Address: " L2_TOKEN_ADDRESS

#export env variables:
export PRIVATE_KEY
export L1_TOKEN_ADDRESS
export L2_TOKEN_ADDRESS


#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1CustomERC20GatewaySetup.s.sol:UpdateTokenMapping \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "L1_TOKEN_ADDRESS=$L1_TOKEN_ADDRESS" --env "L2_TOKEN_ADDRESS=$L2_TOKEN_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
