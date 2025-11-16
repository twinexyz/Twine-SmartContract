#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#export env variables:
export L1_PRIVATE_KEY

#Run the forge script with the provided values
forge script script/view/L1ViewFunctions/ViewL1CustomERC20GatewayState.s.sol:ViewTwineMessenger \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast