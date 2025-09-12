#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#export env variables:
export PRIVATE_KEY

#Run the forge script with the provided values
forge script script/view/L1ViewFunctions/ETHGatewayView.s.sol:ViewL2TokenAddress \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "PRIVATE_KEY=$PRIVATE_KEY"