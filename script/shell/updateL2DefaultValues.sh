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
    #Deployements
   
    "script/shell/deployments/L2deployments/deployEveryL2Contracts.sh"

    # L2 Setups
    "script/shell/setups/L2Setups/setupEveryL2Contracts.sh" 
    "script/shell/setups/L2Setups/setupL2forSolana.sh" 

    
    # L2 Actions
    "script/shell/actions/L2actions/erc20withdraw.sh" 
    "script/shell/actions/L2actions/ethwithdraw.sh" 
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