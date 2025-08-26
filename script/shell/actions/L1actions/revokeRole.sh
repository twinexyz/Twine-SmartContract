#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"

read -p "Account to revoke the role from: " Account
read -p "ROLE (CHAIN_ADMIN, TWINE_CHAIN, TWINE_OPERATIONS_HANDLER, TWINE_GATEWAYS): " ROLE

# export env variables:
export PRIVATE_KEY
export Account
export ROLE

# Run the forge script
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:RevokeRole \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
     -- --env "PRIVATE_KEY=$PRIVATE_KEY" --env "Account=$Account" --env "ROLE=$ROLE"