#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"


#prompt the user
read -p "Counterpart Messenger: " COUNTERPART_MESSENGER

#export env variables:
export PRIVATE_KEY
export COUNTERPART_MESSENGER

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1TwineMessengerSetup.s.sol:SetCounterpartMessenger \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "COUNTERPART_MESSENGER=$COUNTERPART_MESSENGER" --env "PRIVATE_KEY=$PRIVATE_KEY"
