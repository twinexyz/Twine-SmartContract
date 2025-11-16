#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

read -p "L1 Token Address: " L1_TOKEN_ADDRESS

#export env variables:
export L1_PRIVATE_KEY
export L1_TOKEN_ADDRESS

#Run the forge script with the provided values
forge script script/view/L1ViewFunctions/ViewL1CustomERC20GatewayState.s.sol:ViewTokenMapping \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast