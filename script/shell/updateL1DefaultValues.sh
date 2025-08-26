#!/bin/bash

# Prompt for new default values
read -p "Enter new PRIVATE_KEY: " NEW_PRIVATE_KEY
read -p "Enter new DEFAULT_FORK_URL: " NEW_FORK_URL


# Determine OS and set appropriate sed arguments in an array
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS requires an empty string after -i
    sed_args=(-i '' )
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Linux or Windows (with Git Bash/Cygwin) does not require the empty string
    sed_args=(-i)
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Define the files to be updated
FILES=(
    #<---------------------------- Deployement ---------------------------->
    "script/shell/deployments/L1deployments/deployEveryL1Contracts.sh"

    #<------------------------------- Setups ------------------------------->
     "script/shell/setups/L1Setups/setupEveryL1Contracts.sh"

    # CustomERC20Gateway Setup
    "script/shell/setups/L1Setups/CustomERC20GatewaySetup/setChainIdCG.sh"
    "script/shell/setups/L1Setups/CustomERC20GatewaySetup/setGatewayRouterCG.sh"
    "script/shell/setups/L1Setups/CustomERC20GatewaySetup/setRoleManagerCG.sh"
    "script/shell/setups/L1Setups/CustomERC20GatewaySetup/setTwineMessengerCG.sh"
    "script/shell/setups/L1Setups/CustomERC20GatewaySetup/updateTokenMappingCG.sh"

    # L1ETHGateway Setup
    "script/shell/setups/L1Setups/L1ETHGatewaySetup/setChainIdETH.sh"
    "script/shell/setups/L1Setups/L1ETHGatewaySetup/setGatewayRouterETH.sh"
    "script/shell/setups/L1Setups/L1ETHGatewaySetup/setL2TokenETH.sh"
    "script/shell/setups/L1Setups/L1ETHGatewaySetup/setRoleManagerETH.sh"
    "script/shell/setups/L1Setups/L1ETHGatewaySetup/setTwineMessengerETH.sh"

    # L1GatewayRouter Setup
    "script/shell/setups/L1Setups/L1GatewayRouterSetup/setDefaultERC20GatewayGR.sh"
    "script/shell/setups/L1Setups/L1GatewayRouterSetup/setERC20GatewayGR.sh"
    "script/shell/setups/L1Setups/L1GatewayRouterSetup/setETHGatewayGR.sh"
    "script/shell/setups/L1Setups/L1GatewayRouterSetup/setRoleManagerGR.sh"

    # MessageHandler Setup
    "script/shell/setups/L1Setups/L1MessageHandlerSetup/setChainIdMQ.sh"
    "script/shell/setups/L1Setups/L1MessageHandlerSetup/setMessageProxyMQ.sh"
    "script/shell/setups/L1Setups/L1MessageHandlerSetup/setRoleManagerMQ.sh"
    "script/shell/setups/L1Setups/L1MessageHandlerSetup/setTwineMessengerMQ.sh"

    # L1Messenger Setup
    "script/shell/setups/L1Setups/L1MessengerSetup/setCounterpartMessengerMS.sh"
    "script/shell/setups/L1Setups/L1MessengerSetup/setFeeVaultMS.sh"
    "script/shell/setups/L1Setups/L1MessengerSetup/setMessageHandlerMS.sh"
    "script/shell/setups/L1Setups/L1MessengerSetup/setRoleManagerMS.sh"
    "script/shell/setups/L1Setups/L1MessengerSetup/setRollupMS.sh"

    # TwineChain Setup
    "script/shell/setups/L1Setups/TwineChainSetup/setChainIdTC.sh"
    "script/shell/setups/L1Setups/TwineChainSetup/setGatewayTC.sh"
    "script/shell/setups/L1Setups/TwineChainSetup/setMessageHandlerTC.sh"
    "script/shell/setups/L1Setups/TwineChainSetup/setRoleManagerTC.sh"
    "script/shell/setups/L1Setups/TwineChainSetup/setVerifierTC.sh"
    "script/shell/setups/L1Setups/TwineChainSetup/setVkeysTC.sh"

    #<------------------------------- Actions ------------------------------->
    "script/shell/actions/L1actions/commitAndFinalizeBatch.sh" 
    "script/shell/actions/L1actions/commitBatch.sh" 
    "script/shell/actions/L1actions/commitGenesisBlock.sh" 
    "script/shell/actions/L1actions/erc20deposit.sh" 
    "script/shell/actions/L1actions/erc20forcedWithdraw.sh" 
    "script/shell/actions/L1actions/ethdeposit.sh" 
    "script/shell/actions/L1actions/ethforcedWithdraw.sh" 
    "script/shell/actions/L1actions/finalizeBatch.sh" 
    "script/shell/actions/L1actions/finalizeWithdrawal.sh" 
    "script/shell/actions/L1actions/grantRole.sh" 
    "script/shell/actions/L1actions/refundDeposit.sh" 
    "script/shell/actions/L1actions/revokeRole.sh" 
)

# Loop through each file and update the default values
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        # Replace the PRIVATE_KEY value
        sed "${sed_args[@]}" "s|^PRIVATE_KEY=.*|PRIVATE_KEY=\"$NEW_PRIVATE_KEY\"|" "$FILE"

        # Replace the DEFAULT_FORK_URL value
        sed "${sed_args[@]}" "s|^DEFAULT_FORK_URL=.*|DEFAULT_FORK_URL=\"$NEW_FORK_URL\"|" "$FILE"

        echo "Updated $FILE"
    else
        echo "File $FILE not found!"
    fi
done

echo "All files updated successfully!"

#!/bin/bash