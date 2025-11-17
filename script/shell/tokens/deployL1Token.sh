#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Token Name: " TOKEN_NAME
read -p "Token Symbol" TOKEN_SYMBOL
read -p "Token Decimal" TOKEN_DECIMAL

#export env variables:
export L1_PRIVATE_KEY
export TOKEN_NAME
export TOKEN_SYMBOL
export TOKEN_DECIMAL

# Run the forge script
forge script script/tokens/deployL1Token.s.sol:DeployL1ERC20Token \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 