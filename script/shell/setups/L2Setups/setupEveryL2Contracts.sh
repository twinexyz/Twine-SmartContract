#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# export env variables:
export PRIVATE_KEY

#Run the forge script
forge script script/setup/L2SetupScripts/L2SetupScript.s.sol:L2SetupScript \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "PRIVATE_KEY=$PRIVATE_KEY"