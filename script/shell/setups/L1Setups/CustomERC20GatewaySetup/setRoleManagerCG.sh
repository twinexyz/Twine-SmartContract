#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi


#prompt the user
read -p "Role Manager Address: " ROLE_MANAGER_ADDRESS

#export env variables:
export PRIVATE_KEY
export ROLE_MANAGER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1CustomERC20GatewaySetup.s.sol:SetRoleManagerAddress \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "ROLE_MANAGER_ADDRESS=$ROLE_MANAGER_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
