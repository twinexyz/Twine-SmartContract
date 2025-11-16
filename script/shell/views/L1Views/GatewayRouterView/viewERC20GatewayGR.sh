#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

read -p "ERC20 Token Address:" TOKEN
 
#export env variables:
export L1_PRIVATE_KEY
export TOKEN

#Run the forge script with the provided values
forge script script/view/L1ViewFunctions/L1GatewayRouterView.s.sol:ViewERC20Gateway \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast