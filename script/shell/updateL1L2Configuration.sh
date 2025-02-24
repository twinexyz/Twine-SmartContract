#!/bin/bash

# Prompt for new default values
read -p "Enter L1_CHAIN_NAME (holesky,sepolia): " l1_chain_name
read -p "Enter L1_RPC:(https://1rpc.io/holesky): " l1_rpc
read -p "Enter L1_PRIVATE_KEY:" l1_key
read -p "Enter TWINE_RPC (http://rpc1.twine.limited): " twine_rpc
read -p "Enter TWINE_PRIVATE_KEY:" twine_key


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
FILE="script/configure.sh"


# Loop through each file and update the default values
    if [ -f "$FILE" ]; then
        # Replace the l1 Chain Name value
        sed "${sed_args[@]}" "s|^ONE_L1_CHAIN_NAME=.*|ONE_L1_CHAIN_NAME=\"$l1_chain_name\"|" "$FILE"
          # Replace the private key value
        sed "${sed_args[@]}" "s|^ONE_L1_PRIVATE_KEY=.*|ONE_L1_PRIVATE_KEY=\"$l1_key\"|" "$FILE"
             # Replace the L1 RPC value
        sed "${sed_args[@]}" "s|^ONE_L1_RPC=.*|ONE_L1_RPC=\"$l1_rpc\"|" "$FILE"
          # Replace the Twine RPC value
        sed "${sed_args[@]}" "s|^TWINE_RPC=.*|TWINE_RPC=\"$twine_rpc\"|" "$FILE"
        # Replace the Twine Private Key value
        sed "${sed_args[@]}" "s|^TWINE_PRIVATE_KEY=.*|TWINE_PRIVATE_KEY=\"$twine_key\"|" "$FILE"

        echo "Updated $FILE"
    else
        echo "File $FILE not found!"
    fi
done

echo "All files updated successfully!"

#!/bin/bash