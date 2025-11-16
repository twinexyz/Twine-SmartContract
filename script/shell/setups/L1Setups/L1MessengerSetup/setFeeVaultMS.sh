#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Fee Vault: " FEE_VAULT

#export env variables:
export L1_PRIVATE_KEY
export FEE_VAULT

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1TwineMessengerSetup.s.sol:SetFeeValut \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 