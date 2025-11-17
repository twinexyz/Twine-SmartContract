#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

read -p "Account to grant the role: " Account
read -p "ROLE (CHAIN_ADMIN, TWINE_CHAIN, TWINE_OPERATIONS_HANDLER, TWINE_GATEWAYS): " ROLE

# export env variables:
export L1_PRIVATE_KEY
export Account
export ROLE

# Run the forge script
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:GrantRole \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 