#!/bin/bash

# Prompt for new default values
read -p "Enter new PRIVATE_KEY: " NEW_PRIVATE_KEY
read -p "Enter new DEFAULT_FORK_URL: " NEW_FORK_URL

# Define the files to be updated
FILES=(
    "script/shell/deployments/L1deployments/deployEveryL1Contracts.sh"
    "script/shell/deployments/L2deployments/deployEveryL2Contracts.sh"
    "script/shell/setups/L1Setups/setupEveryL1Contracts.sh" 
    "script/shell/setups/L2Setups/setupEveryL2Contracts.sh" 
    "script/shell/actions/L1actions/ethdeposit.sh" 
    )

# Loop through each file and update the default values
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        # Replace the PRIVATE_KEY value
        sed -i "s|^PRIVATE_KEY=.*|PRIVATE_KEY=\"$NEW_PRIVATE_KEY\"|" "$FILE"
        
        # Replace the DEFAULT_FORK_URL value
        sed -i "s|^DEFAULT_FORK_URL=.*|DEFAULT_FORK_URL=\"$NEW_FORK_URL\"|" "$FILE"
        
        echo "Updated $FILE"
    else
        echo "File $FILE not found!"
    fi
done

echo "All files updated successfully!"
