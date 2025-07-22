#!/bin/bash

update_solidity_version() {
    local file_path="$1"
    local new_version="pragma solidity ^0.8.20;"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' '3c\
        pragma solidity ^0.8.20;' "$file_path"
    else
        # Linux
        sed -i '3c\pragma solidity ^0.8.20;' "$file_path"
    fi

    echo "Updated Solidity version in $file_path"
}

# Initialize and update submodules
echo "Initializing and updating submodules..."
git submodule update --init --recursive

# Update the Solidity version in Groth16Verifier.sol
echo "Updating Solidity version in Groth16Verifier.sol..."
update_solidity_version "lib/sp1-contracts/contracts/src/v5.0.0/Groth16Verifier.sol"

# Build the contracts
echo "Building contracts..."
forge build
cd lib/sp1-contracts/contracts
forge build
cd -

echo "Solidity Version changed successfully!"