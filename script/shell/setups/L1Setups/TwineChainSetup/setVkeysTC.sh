#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"


#prompt the user
read -p "Finalize Vkey: " FINALIZE_VKEY
read -p "Refund VKey: " REFUND_VKEY
read -p "Withdrawal Vkey: " WITHDRAWAL_VKEY
#export env variables:
export PRIVATE_KEY
export FINALIZE_VKEY
export REFUND_VKEY
export WITHDRAWAL_VKEY

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/TwineChainSetup.s.sol:SetProgramVkey \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "FINALIZE_VKEY=$FINALIZE_VKEY" --env "REFUND_VKEY=$REFUND_VKEY" \
    --env "WITHDRAWAL_VKEY=$WITHDRAWAL_VKEY" --env "PRIVATE_KEY=$PRIVATE_KEY"
