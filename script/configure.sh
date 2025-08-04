#!/bin/bash
# This should be run from the project root

ENV_FILE=".env"
MARKER="marker"

ONE_L1_CHAIN_NAME="L1"
ONE_L1_RPC="http://127.0.0.1:8570"
ONE_L1_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
ONE_L1_EXECUTION_VKEY=0xdd5ee6eba326044043ebbfd5332d3a2faba338d85a6d4fd75210ec22bd9cd290
ONE_L1_TRANSACTION_INCLUSION_VKEY=0xdd5ee6eba326044043ebbfd5332d3a2faba338d85a6d4fd75210ec22bd9cd290
ONE_L1_WITHDRAW_VKEY=0xdd5ee6eba326044043ebbfd5332d3a2faba338d85a6d4fd75210ec22bd9cd290
ONE_L1_FAUX_COIN=0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
ONE_L1_SP1_VERIFIER=0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e

TWINE_CHAIN_NAME=twine
TWINE_RPC="http://127.0.0.1:8545"
TWINE_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

ONE_L1_ADDRESSES="script/utils/${ONE_L1_CHAIN_NAME}Addresses.json"
TWINE_ADDRESSES="script/utils/${TWINE_CHAIN_NAME}Addresses.json"
DEPLOYED_CONTRACTS="script/utils/deployedContracts.json"

L1_DEPLOYMENT_MARKER="$MARKER/L1_deployment_marker.txt"
L2_DEPLOYMENT_MARKER="$MARKER/L2_deployment_marker.txt"
L1_SETUP_MARKER="$MARKER/L1_setup_marker.txt"
L2_SETUP_MARKER="$MARKER/L2_setup_marker.txt"

touch $ONE_L1_ADDRESSES
touch $TWINE_ADDRESSES

if [ "$1" == "--clear" ]; then
  if [ -d "$MARKER" ]; then
    rm -rf "$MARKER"
    echo "Marker removed."
  else
    echo "Marker does not exist."
  fi
fi

mkdir -p $MARKER

function load_l1_env() {
    >"$ENV_FILE"
    cat <<EOF >"$ENV_FILE"
CHAIN_NAME=$ONE_L1_CHAIN_NAME
PRIVATE_KEY=$ONE_L1_PRIVATE_KEY
ADDRESSES_EXPORT_PATH=$ONE_L1_ADDRESSES
EOF
    source $ENV_FILE
}

function load_l2_env() {
    >"$ENV_FILE"
    cat <<EOF >"$ENV_FILE"
CHAIN_NAME=$TWINE_CHAIN_NAME
PRIVATE_KEY=$TWINE_PRIVATE_KEY
EOF
    source $ENV_FILE
}

run_if_not_done() {
  local marker_file=$1
  local command=$2
  local failure_message=$3
  local type=$4
  
  if [ -f "$marker_file" ]; then
    echo "🫸🫸  $type Artifact exists. Skipping...  "
  else
    echo "Running command: $command"
    $command
    
    if [ $? -eq 0 ]; then
      echo 
      echo "*************************************************"
      echo "💚💛 $type Successful!"
      echo "*************************************************"
      echo 
      echo $type > "$marker_file"  # Save marker on success
    else
      echo
      echo "*************************************************"
      echo "$failure_message"
      echo "*************************************************"
      echo
    fi
  fi
}


# Deploy on Twine
load_l2_env
forge clean

L2_DEPLOY_CMD="forge script script/deploy/L2DeploymentScripts/DeployL2Contracts.s.sol --broadcast --rpc-url $TWINE_RPC"
run_if_not_done "$L2_DEPLOYMENT_MARKER" "$L2_DEPLOY_CMD" "L2 Deployment failed." "Deploy"

# Deploy on L1
load_l1_env
forge clean

L1_DEPLOY_CMD="forge script script/deploy/L1DeploymentScripts/DeployL1Contracts.s.sol --broadcast --rpc-url $ONE_L1_RPC"
run_if_not_done "$L1_DEPLOYMENT_MARKER" "$L1_DEPLOY_CMD"  "L1 Deployment failed." "Deploy"

jq --arg vkey "$ONE_L1_EXECUTION_VKEY" '.finalizeVkey = $vkey' "$ONE_L1_ADDRESSES" >temp.json && mv temp.json "$ONE_L1_ADDRESSES"
jq --arg vkey "$ONE_L1_TRANSACTION_INCLUSION_VKEY" '.refundVkey = $vkey' "$ONE_L1_ADDRESSES" >temp.json && mv temp.json "$ONE_L1_ADDRESSES"
jq --arg vkey "$ONE_L1_WITHDRAW_VKEY" '.withdrawalVkey = $vkey' "$ONE_L1_ADDRESSES" >temp.json && mv temp.json "$ONE_L1_ADDRESSES"
jq --arg vkey "$ONE_L1_SP1_VERIFIER" '.Verifier = $vkey' "$ONE_L1_ADDRESSES" >temp.json && mv temp.json "$ONE_L1_ADDRESSES"

dev_contracts=$(cat "$ONE_L1_ADDRESSES")
twine_contracts=$(cat "$TWINE_ADDRESSES")

json_output=$(jq -n \
  --argjson dev "$dev_contracts" \
  --argjson twine "$twine_contracts" \
  '{Dev1: $dev, Twine: $twine}')

# Output the final JSON to a file or print to console
echo "$json_output" > $DEPLOYED_CONTRACTS

# Setup L1
load_l1_env
L1_SETUP_CMD="forge script script/setup/L1SetupScripts/L1SetupScript.s.sol --broadcast --rpc-url $ONE_L1_RPC"
run_if_not_done "$L1_SETUP_MARKER" "$L1_SETUP_CMD"  "L1 Setup failed." "Setup"

# Setup L2
load_l2_env
L2_SETUP_CMD="forge script script/setup/L2SetupScripts/L2SetupScript.s.sol --broadcast --rpc-url $TWINE_RPC"
run_if_not_done "$L2_SETUP_MARKER" "$L2_SETUP_CMD"  "L2 Setup failed." "Setup"

# Clear .env
>"$ENV_FILE"