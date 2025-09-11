#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Message Handler: " MESSAGE_QUEUE_ADDRESS

#export env variables:
export PRIVATE_KEY
export MESSAGE_QUEUE_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1TwineMessengerSetup.s.sol:setMessageHandlerAddress \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "MESSAGE_QUEUE_ADDRESS=$MESSAGE_QUEUE_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
