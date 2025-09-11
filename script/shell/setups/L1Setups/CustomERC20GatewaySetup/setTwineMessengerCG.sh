#!/bin/bash

if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
fi

#prompt the user
read -p "Twine Messenger Address: " TWINE_MESSENGER_ADDRESS

#export env variables:
export PRIVATE_KEY
export TWINE_MESSENGER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/L1CustomERC20GatewaySetup.s.sol:SetTwineMessenger \
    --fork-url "$DEFAULT_FORK_URL"  \
    --broadcast \
    -- --env "TWINE_MESSENGER_ADDRESS=$TWINE_MESSENGER_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
