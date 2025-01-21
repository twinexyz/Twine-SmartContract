# ******************************************************* 
# *						Utility Scripts					*
# *******************************************************

# Update the default value of PrivateKey and ForkURL in every file
updateDefaultValues:
	bash script/shell/updateDefaultValues.sh


# *************************************************** 
# *						L1 Scripts					*
# ***************************************************

# *********************** 
# *		DEPLOYMENTS		*
# ***********************

# deploy every L1 contract
deployEveryL1Contracts:
	bash script/shell/deployments/L1deployments/deployEveryL1Contracts.sh


# *******************
# *		SETUPS		*
# *******************

#<-------------SETUP EVERYTHING------------->

#setup every L1 contract
setupEveryL1Contracts:
	bash script/shell/setups/L1setups/setupEveryL1Contracts.sh

#<-------------TWINE CHAIN SETUPS------------->

#setup rolemanager
setupRoleManagerTwineChain:
	bash script/shell/setups/L1Setups/TwineChainSetup/setRoleManagerTC.sh

#setup chain id 
setupChainIdTwineChain:
	bash script/shell/setups/L1Setups/TwineChainSetup/setChainIdTC.sh

#setup message queue 
setupMessageQueueTwineChain:
	bash script/shell/setups/L1Setups/TwineChainSetup/setMessageQueueTC.sh

#setup verifier
setupVerifierTwineChain:
	bash script/shell/setups/L1Setups/TwineChainSetup/setVerifierTC.sh

#setup program V keys
setupVkeysTwineChain:
	bash script/shell/setups/L1Setups/TwineChainSetup/setVkeysTC.sh

#setup gateway
setupGatewayTwineChain:
	bash script/shell/setups/L1Setups/TwineChainSetup/setGatewayTC.sh

#<-------------ETH GATEWAY SETUP------------->

#setup role manager

#setup gateway router

#setup twine messenger

#setup L2 Token Address

#<-------------MESSAGE QUEUE SETUP------------->


#<-------------GATEWAY ROUTER SETUP------------->

#<-------------MESSENGER SETUP------------->

#<-------------CUSTOM ERC20 SETUP------------->





# *******************
# *		ACTIONS		*
# *******************

#<-------------ETH GATEWAY ACTIONS------------->

# initiate eth deposit
depositETH:
	bash script/shell/actions/L1actions/ethdeposit.sh

# initiate forced withdraw of eth
forcedWithdrawETH:
	bash script/shell/actions/L1actions/ethforcedWithdraw.sh

#<-------------ERC20 GATEWAY ACTIONS------------->

# initiate erc20 deposit
depositERC20:
	bash script/shell/actions/L1actions/erc20deposit.sh

# initiate forced withdraw of erc20
forcedWithdrawERC20:
	bash script/shell/actions/L1actions/erc20forcedWithdraw.sh

#<-------------TWINE CHAIN ACTIONS------------->

# commit and finalize a batch
commitAndFinalizeBatch:
	bash script/shell/actions/L1actions/commitAndFinalize.sh

# commit and finalize transaction for a batch
commitAndFinalizeTransaction:
	bash script/shell/actions/L1actions/commitAndFinalizeTxn.sh

# finalize a withdrawal
finalizeWithdrawal:
	bash script/shell/actions/L1actions/finalizeWithdrawal.sh


# *************************************************** 
# *						L2 Scripts					*
# ***************************************************

# *************** 
# *	DEPLOYMENTS	*
# ***************

# deploy every L2 contract
deployEveryL2Contracts:
	bash script/shell/deployments/L2deployments/deployEveryL2Contracts.sh

# ***********
# *	SETUPS	*
# ***********

#setup every L2 contract
setupEveryL2Contracts:
	bash script/shell/setups/L2setups/setupEveryL2Contracts.sh


	