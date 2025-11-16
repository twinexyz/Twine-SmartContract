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
export L1_PRIVATE_KEY

# Run the forge script with the provided default values
forge script script/action/L1ActionScripts/L1ActionScripts.s.sol:FinalizeBatch \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 