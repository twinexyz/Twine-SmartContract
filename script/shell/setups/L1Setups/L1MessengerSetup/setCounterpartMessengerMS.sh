#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi


#prompt the user
read -p "Counterpart Messenger: " COUNTERPART_MESSENGER

#export env variables:
export PRIVATE_KEY
export COUNTERPART_MESSENGER

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1TwineMessengerSetup.s.sol:SetCounterpartMessenger \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "COUNTERPART_MESSENGER=$COUNTERPART_MESSENGER" --env "PRIVATE_KEY=$PRIVATE_KEY"
