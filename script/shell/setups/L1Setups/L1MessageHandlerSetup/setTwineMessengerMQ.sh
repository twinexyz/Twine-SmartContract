#!/bin/bash
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "L1 Messenger Address: " L1_MESSENGER_ADDRESS

#export env variables:
export PRIVATE_KEY
export L1_MESSENGER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/MessageHandlerSetup.s.sol:SetMessagengerAddress \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "L1_MESSENGER_ADDRESS=$L1_MESSENGER_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
