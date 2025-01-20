# ******************************************************* 
# *						Utility Scripts					*
# *******************************************************

# Update the default value of PrivateKey and ForkURL in every file
updateDefaultValues:
	bash script/shell/updateDefaultValues.sh


# *************************************************** 
# *						L1 Scripts					*
# ***************************************************

# DEPLOYMENTS:

# deploy every L1 contract
deployEveryL1Contracts:
	bash script/shell/deployments/L1deployments/deployEveryL1Contracts.sh

# SETUPS:

#setup every L1 contract
setupEveryL1Contracts:
	bash script/shell/setups/L1setups/setupEveryL1Contracts.sh

# ACTIONS:

# initiate eth deposit
depositETH:
	bash script/shell/actions/L1Actions/ethdeposit.sh


# *************************************************** 
# *						L2 Scripts					*
# ***************************************************

# DEPLOYMENTS:

# deploy every L2 contract
deployEveryL2Contracts:
	bash script/shell/deployments/L2deployments/deployEveryL2Contracts.sh


# SETUPS:

#setup every L2 contract
setupEveryL2Contracts:
	bash script/shell/setups/L2setups/setupEveryL2Contracts.sh


	