#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="127.0.0.1:8545"


#prompt the user
read -p "Twine Messenger: " TWINE_MESSENGER_ADDRESS

#export env variables:
export PRIVATE_KEY
export TWINE_MESSENGER_ADDRESS

#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/ETHGatewaySetup.s.sol:setTwineMessenger \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "TWINE_MESSENGER_ADDRESS=$TWINE_MESSENGER_ADDRESS" --env "PRIVATE_KEY=$PRIVATE_KEY"
