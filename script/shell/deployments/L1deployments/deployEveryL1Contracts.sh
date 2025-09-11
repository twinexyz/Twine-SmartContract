#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# export env variables:
export PRIVATE_KEY

#Run the forge script
forge script script/deploy/L1DeploymentScripts/DeployL1Contracts.s.sol:DeployL1Contracts \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "PRIVATE_KEY=$PRIVATE_KEY"