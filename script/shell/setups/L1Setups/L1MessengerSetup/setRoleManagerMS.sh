#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Role Manager Address: " ROLE_MANAGER_ADDRESS

#export env variables:
export L1_PRIVATE_KEY
export ROLE_MANAGER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1TwineMessengerSetup.s.sol:SetRoleManagerAddress \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast