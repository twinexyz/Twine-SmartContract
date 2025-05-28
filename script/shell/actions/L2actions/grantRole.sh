#!/bin/bash

# Default values
PRIVATE_KEY="0x63ff47b31d047d471229d35e0e2b829708dde1f1e438bfaf1059d0de785dedc1"
DEFAULT_FORK_URL="https://rpc1.twine.limited/"

read -p "Account to grant the role: " Account
read -p "ROLE (CHAIN_ADMIN, TWINE_CHAIN, TWINE_OPERATIONS_HANDLER, TWINE_GATEWAYS): " ROLE

# export env variables:
export PRIVATE_KEY
export Account
export ROLE

# Run the forge script
forge script script/action/L2ActionScripts/L2ActionScripts.s.sol:GrantRole \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
     -- --env "PRIVATE_KEY=$PRIVATE_KEY" --env "Account=$Account" --env "ROLE=$ROLE"