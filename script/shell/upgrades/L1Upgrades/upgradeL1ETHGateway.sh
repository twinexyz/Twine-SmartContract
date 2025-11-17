#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# export env variables:
export L1_PRIVATE_KEY

# Run the forge script
forge script script/upgrade/L1UpgradeScripts/UpgradeL1Contracts.s.sol:UpgradeL1ETHGateway \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast