#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# export env variables:
export PRIVATE_KEY

# Run the forge script
forge script script/upgrade/L1UpgradeScripts/UpgradeL1Contracts.s.sol:UpgradeTwineChain \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
     -- --env "PRIVATE_KEY=$PRIVATE_KEY" 