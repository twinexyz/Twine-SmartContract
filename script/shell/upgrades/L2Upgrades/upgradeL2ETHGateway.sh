#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# export env variables:
export PRIVATE_KEY

# Run the forge script
forge script script/upgrade/L2UpgradeScripts/UpgradeL2Contracts.s.sol:UpgradeL2ETHGateway \
    --fork-url "$L2_DEFAULT_FORK_URL"  \
    --broadcast \
     -- --env "PRIVATE_KEY=$PRIVATE_KEY" 