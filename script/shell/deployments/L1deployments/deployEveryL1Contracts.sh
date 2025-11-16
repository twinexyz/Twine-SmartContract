#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# export env variables:
export L1_PRIVATE_KEY

#Run the forge script
forge script script/deploy/L1DeploymentScripts/DeployL1Contracts.s.sol:DeployL1Contracts \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 