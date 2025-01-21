#!/bin/bash

# Default values
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_FORK_URL="http://127.0.0.1:8545"

#prompt the user
read -p "Execution Vkey: " ETH_GATEWAY
read -p "Inclusion VKey: " ERC20_GATEWAY

#export env variables:
export PRIVATE_KEY
export ETH_GATEWAY
export ERC20_GATEWAY


#Run the forge script with the provided values
forge script script/setup/L1SetupScripts/TwineChainSetup.s.sol:SetGatewayAddress \
    --fork-url $DEFAULT_FORK_URL  \
    --broadcast \
    -- --env "ETH_GATEWAY=$ETH_GATEWAY" --env "ERC20_GATEWAY=$ERC20_GATEWAY" --env "PRIVATE_KEY=$PRIVATE_KEY"
