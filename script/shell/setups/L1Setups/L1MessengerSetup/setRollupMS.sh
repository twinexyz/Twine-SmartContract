#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Rollup Address(TwineChain): " ROLLUP_ADDRESS

#export env variables:
export L1_PRIVATE_KEY
export ROLLUP_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1TwineMessengerSetup.s.sol:SetRollupAddress \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 