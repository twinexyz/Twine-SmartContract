#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Finalize Vkey: " FINALIZE_VKEY
read -p "Refund VKey: " REFUND_VKEY
read -p "Forced Withdrawal VKey: " FORCED_WITHDRAWAL_VKEY
read -p "L2 Withdrawal Vkey: " L2_WITHDRAWAL_VKEY
#export env variables:
export L1_PRIVATE_KEY
export FINALIZE_VKEY
export REFUND_VKEY
export FORCED_WITHDRAWAL_VKEY
export L2_WITHDRAWAL_VKEY

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/TwineChainSetup.s.sol:SetProgramVkey \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast 