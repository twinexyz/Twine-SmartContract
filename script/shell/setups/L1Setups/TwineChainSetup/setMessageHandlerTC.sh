#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Message Handler Address: " MESSAGE_HANDLER_ADDRESS

#export env variables:
export PRIVATE_KEY
export MESSAGE_HANDLER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/TwineChainSetup.s.sol:SetMessageHandlerAddress \
    --fork-url "$L1_DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "MESSAGE_HANDLER_ADDRESS=$MESSAGE_HANDLER_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
