#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

# Prompt user for start and end blocks
read -p "Public input: " PUBLIC_INPUT_FOR_REFUND
read -p "Refund Proof: " REFUND_PROOF

# export env variables:
export PUBLIC_INPUT_FOR_REFUND
export REFUND_PROOF
export PRIVATE_KEY

# Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:FinalizeBatch \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "PUBLIC_INPUT_FOR_REFUND=$PUBLIC_INPUT_FOR_REFUND" --env "REFUND_PROOF=$REFUND_PROOF" --env "PRIVATE_KEY=$PRIVATE_KEY"
