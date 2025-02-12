
# ******************************************************* 
# *					Available commands					*
# *******************************************************

help:
	@echo "Available targets:"
	@echo "  help                 	     - Show this help message"
	@echo "  updateDefaultValues        - update private key and rpc url"
	@echo "  deployEveryL1Contracts     - deploy L1 contracts"
	@echo "  depositETH                 - deposit ETH in L1"
	@echo "  forcedWithdrawETH          - initiates Ethwithdraw from L1"
	@echo "  depositERC20               - deposit ERC20 in L1"
	@echo "  forcedWithdrawERC20        - initiates ERC20 withdraw from L1"
	@echo "  setupEveryL1Contracts      - setup every l1 contracts"
	@echo "  deployEveryL2Contracts     - deploy L2 Contracts"
	@echo "  WithdrawERC20FromL2 	     - ERC20 withdraw from L2"
	@echo "  setupEveryL2Contracts      - setup every l1 contracts"
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

#<-------------L1 ETH GATEWAY SETUP------------->

#setup role manager
setupRoleManagerL1ETHGateway:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setRoleManagerETH.sh

#setup gateway router
setGatewayRouterL1ETHGateway:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setGatewayRouterETH.sh

#setup twine messenger
setTwineMessengerL1ETHGateway:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setTwineMessengerETH.sh

#setup L2 Token Address
setL2TokenL1ETHGateway:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setL2TokenETH.sh

#<-------------L1 MESSAGE QUEUE SETUP------------->

#setup role manager
setRoleManagerMQ:
	bash script/shell/setups/L1Setups/L1MessageQueueSetup/setRoleManagerMQ.sh

#setup chain id
setChainIdMQ:
	bash script/shell/setups/L1Setups/L1MessageQueueSetup/setChainIdMQ.sh

#setup l1 twine messenger 
setTwineMessengerMQ:
	bash script/shell/setups/L1Setups/L1MessageQueueSetup/setTwineMessengerMQ.sh

#setup message queue proxy
setMessageProxyMQ:
	bash script/shell/setups/L1Setups/L1MessageQueueSetup/setMessageProxyMQ.sh


#<-------------L1 GATEWAY ROUTER SETUP------------->

#setup role manager
setRoleManagerGR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setRoleManagerGR.sh

#setup ETH Gateway
setETHGatewayGR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setETHGatewayGR.sh

#setup Default ERC20 Gateway
setDefaultERC20GatewayGR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setDefaultERC20GatewayGR.sh

#setup ERC20 Gaetway
setERC20GatewayGR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setERC20GatewayGR.sh


#<-------------L1 MESSENGER SETUP------------->

#setup role manager
setRoleManagerMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setRoleManagerMS.sh

#setup rollup
setRollupMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setRollupMS.sh

#setup message queue
setMessageQueueMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setMessageQueueMS.sh

#setup counterpart messenger
setCounterpartMessengerMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setCounterpartMessengerMS.sh

#<-------------L1 CUSTOM ERC20 SETUP------------->

#setup role manager
setRoleManagerCG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/setRoleManagerCG.sh

#setup gateway router
setGatewayRouterCG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/setGatewayRouterCG.sh

#setup twine messenger
setTwineMessengerCG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/setTwineMessengerCG.sh

#update token mapping
updateTokenMappingCG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/updateTokenMappingCG.sh


# *************************************************** 
# *						L2 Scripts					*
# ***************************************************

# *********************** 
# *		DEPLOYMENTS		*
# ***********************

# deploy every L2 contract
deployEveryL2Contracts:
	bash script/shell/deployments/L2deployments/deployEveryL2Contracts.sh

# *******************
# *		ACTIONS		*
# *******************

#withdraw ETH
	bash script/shell/actions/L2actions/ethwithdraw.sh


#withdraw ERC20
WithdrawERC20FromL2:
	bash script/shell/actions/L2actions/erc20withdraw.sh


# *******************
# *		SETUPS		*
# *******************

#setup every L2 contract
setupEveryL2Contracts:
	bash script/shell/setups/L2setups/setupEveryL2Contracts.sh


	