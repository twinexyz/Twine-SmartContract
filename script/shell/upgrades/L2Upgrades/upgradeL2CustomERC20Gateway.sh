#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# export env variables:
export L2_PRIVATE_KEY

# Run the forge script
forge script script/upgrade/L2UpgradeScripts/UpgradeL2Contracts.s.sol:UpgradeL2CustomERC20Gateway \
    --fork-url "$L2_DEFAULT_FORK_URL"  \
    --broadcast