MARKER_FILE = marker
# ******************************************************* 
# *					Available commands					*
# *******************************************************

help:
	@echo "========================================================="
	@echo "               Available Targets Help                    "
	@echo "========================================================="
	@echo "help                            - Show this help message"
	@echo "build  							- Build contracts "
	@echo "clean                     		- Remove build artifacts"
	@echo "updateSp1Version                - Update sp1 library version in build file"
	@echo "updateL1DefaultValues           - Update private key and RPC URL for L1"
	@echo "updateL2DefaultValues           - Update private key and RPC URL for L2"
	@echo "deployEveryL1Contracts          - Deploy all L1 contracts"
	@echo "depositETH                      - Deposit ETH on L1"
	@echo "forcedWithdrawETH               - Initiate forced ETH withdrawal from L1"
	@echo "depositERC20                    - Deposit ERC20 tokens on L1"
	@echo "forcedWithdrawERC20             - Initiate forced ERC20 withdrawal from L1"
	@echo "setupEveryL1Contracts           - Set up every L1 contract"
	@echo "deployEveryL2Contracts          - Deploy all L2 contracts"
	@echo "WithdrawERC20FromL2             - Withdraw ERC20 tokens from L2"
	@echo "setupEveryL2Contracts           - Set up every L2 contract"
	@echo "commitBatch                     - Commit batch transactions"
	@echo "finalizeBatch                   - Finalize batch transactions"
	@echo "commitAndFinalizeTransaction    - Commit and finalize transaction"
	@echo "finalizeWithdrawal              - Finalize a  withdrawal"
	@echo "grantRole                       - Grant a role to an entity"
	@echo "revokeRole                      - Revoke a role from an entity"
	@echo "setupRoleManagerTwineChain      - Configure role manager for Twine Chain"
	@echo "setupChainIdTwineChain          - Configure chain ID for Twine Chain"
	@echo "setupMessageHandlerTwineChain     - Configure message queue for Twine Chain"
	@echo "setupVerifierTwineChain         - Set up verifier for Twine Chain"
	@echo "setupVkeysTwineChain            - Configure program V keys for Twine Chain"
	@echo "setupGatewayTwineChain          - Configure gateway for Twine Chain"
	@echo "setupRoleManagerL1ETHGateway    - Configure role manager for L1 ETH Gateway"
	@echo "setGatewayRouterL1ETHGateway    - Set up gateway router for L1 ETH Gateway"
	@echo "setTwineMessengerL1ETHGateway   - Set up Twine messenger for L1 ETH Gateway"
	@echo "setL2TokenL1ETHGateway          - Configure L2 token address for L1 ETH Gateway"
	@echo "setChainIdL1ETHGateway          - Set Chain Id for Custom ERC20 "
	@echo "setRoleManagerMQ                - Configure role manager for Message Queue"
	@echo "setChainIdMQ                    - Configure chain ID for Message Queue"
	@echo "setTwineMessengerMQ             - Set up Twine messenger for Message Queue"
	@echo "setMessageProxyMQ               - Set up message proxy for Message Queue"
	@echo "setRoleManagerGR                - Configure role manager for Gateway Router"
	@echo "setETHGatewayGR                 - Set up ETH Gateway in Gateway Router"
	@echo "setDefaultERC20GatewayGR        - Set up default ERC20 Gateway in Gateway Router"
	@echo "setERC20GatewayGR               - Set up ERC20 Gateway in Gateway Router"
	@echo "setRoleManagerMS                - Configure role manager for Messenger"
	@echo "setRollupMS                     - Set up rollup for Messenger"
	@echo "setMessageHandlerMS               - Set up message queue for Messenger"
	@echo "setCounterpartMessengerMS       - Set up counterpart messenger"
	@echo "setRoleManagerCG                - Configure role manager for Custom ERC20"
	@echo "setChainIdCG                    - Set Chain Id for Custom ERC20 "
	@echo "setGatewayRouterCG              - Set up gateway router for Custom ERC20"
	@echo "setTwineMessengerCG             - Set up Twine messenger for Custom ERC20"
	@echo "updateTokenMappingCG            - Update token mapping for Custom ERC20"
	@echo "setupEveryContracts             - Setup of both l1 and l2"


# ******************************************************* 
# *						build and clean			        *
# *******************************************************
build:
	@echo "Starting contract compilation..."
	@forge build

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf out cache
# ******************************************************* 
# *						Update sp1 Version			    *
# *******************************************************
updateSp1Version:
	bash script/updateSp1Version.sh

# ******************************************************* 
# *						Utility Scripts					*
# *******************************************************

# Update the default value of PrivateKey and ForkURL in every L1 file
updateL1DefaultValues:
	bash script/shell/updateL1DefaultValues.sh

# Update the default value of PrivateKey and ForkURL in every L2 file
updateL2DefaultValues:
	bash script/shell/updateL2DefaultValues.sh

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

#commit Genesis Block
commitGenesisBlock:
	bash script/shell/actions/L1actions/commitGenesisBlock.sh

# commit batch
commitBatch:
	bash script/shell/actions/L1actions/commitBatch.sh

# finalize batch
finalizeBatch:
	bash script/shell/actions/L1actions/finalizeBatch.sh

# commit and finalize transaction for a batch
commitAndFinalizeBatch:
	bash script/shell/actions/L1actions/commitAndFinalizeBatch.sh

# finalize a withdrawal
refundDeposit:
	bash script/shell/actions/L1actions/refundDeposit.sh


#<-------------ROLE MANAGER ACTIONS------------->
grantRoleL1:
	bash script/shell/actions/L1actions/grantRole.sh

revokeRoleL1:
	bash script/shell/actions/L1actions/revokeRole.sh

grantRoleL2:
	bash script/shell/actions/L2actions/grantRole.sh

revokeRoleL2:
	bash script/shell/actions/L2actions/revokeRole.sh



# *******************
# *		SETUPS		*
# *******************

#<-------------SETUP EVERYTHING------------->

#setup every L1 contract
setupEveryL1Contracts:
	bash script/shell/setups/L1setups/setupEveryL1Contracts.sh

#<-------------TWINE CHAIN SETUPS------------->

#setup rolemanager
setupRoleManagerTC:
	bash script/shell/setups/L1Setups/TwineChainSetup/setRoleManagerTC.sh

#setup chain id 
setupChainIdTC:
	bash script/shell/setups/L1Setups/TwineChainSetup/setChainIdTC.sh

#setup message queue 
setupMessageHandlerTC:
	bash script/shell/setups/L1Setups/TwineChainSetup/setMessageHandlerTC.sh

#setup verifier
setupVerifierTC:
	bash script/shell/setups/L1Setups/TwineChainSetup/setVerifierTC.sh

#setup program V keys
setupVkeysTC:
	bash script/shell/setups/L1Setups/TwineChainSetup/setVkeysTC.sh

#setup gateway
setupGatewayTC:
	bash script/shell/setups/L1Setups/TwineChainSetup/setGatewayTC.sh


#<-------------L1 ETH GATEWAY SETUP------------->

#setup role manager
setupRoleManagerL1EthG:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setRoleManagerETH.sh

#setup gateway router
setGatewayRouterL1EthG:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setGatewayRouterETH.sh

#setup twine messenger
setTwineMessengerL1EthG:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setTwineMessengerETH.sh

#setup L2 Token Address
setL2TokenL1EthG:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setL2TokenETH.sh

setChainIdL1EthG:
	bash script/shell/setups/L1Setups/L1ETHGatewaySetup/setChainIdETH.sh


#<-------------L1 Message Handler SETUP------------->

#setup role manager
setRoleManagerMH:
	bash script/shell/setups/L1Setups/L1MessageHandlerSetup/setRoleManagerMQ.sh

#setup chain id
setChainIdMH:
	bash script/shell/setups/L1Setups/L1MessageHandlerSetup/setChainIdMQ.sh

#setup l1 twine messenger 
setTwineMessengerMH:
	bash script/shell/setups/L1Setups/L1MessageHandlerSetup/setTwineMessengerMQ.sh

#setup message queue proxy
setMessageProxyMH:
	bash script/shell/setups/L1Setups/L1MessageHandlerSetup/setMessageProxyMQ.sh


#<-------------L1 GATEWAY ROUTER SETUP------------->

#setup role manager
setRoleManagerL1GR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setRoleManagerGR.sh

#setup ETH Gateway
setETHGatewayL1GR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setETHGatewayGR.sh

#setup Default ERC20 Gateway
setDefaultERC20GatewayL1GR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setDefaultERC20GatewayGR.sh

#setup ERC20 Gaetway
setERC20GatewayL1GR:
	bash script/shell/setups/L1Setups/L1GatewayRouterSetup/setERC20GatewayGR.sh


#<-------------L1 MESSENGER SETUP------------->

#setup role manager
setRoleManagerMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setRoleManagerMS.sh

#setup rollup
setRollupMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setRollupMS.sh

#setup message queue
setMessageHandlerMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setMessageHandlerMS.sh

#setup counterpart messenger
setCounterpartMessengerMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setCounterpartMessengerMS.sh

#setup FeeVault 
setFeeVaultMS:
	bash script/shell/setups/L1Setups/L1MessengerSetup/setFeeVaultMS.sh


#<-------------L1 CUSTOM ERC20 SETUP------------->

#setup role manager
setRoleManagerL1ErcG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/setRoleManagerCG.sh

#setup gateway router
setGatewayRouterL1ErcG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/setGatewayRouterCG.sh

#setup twine messenger
setTwineMessengerL1ErcG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/setTwineMessengerCG.sh

#update token mapping
updateTokenMappingL1ErcG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/updateTokenMappingCG.sh

#update and set chain Id
setChainIdL1ErcG:
	bash script/shell/setups/L1Setups/CustomERC20GatewaySetup/setChainIdCG.sh


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
#	bash script/shell/actions/L2actions/ethwithdraw.sh


#withdraw ERC20
WithdrawERC20FromL2:
	bash script/shell/actions/L2actions/erc20withdraw.sh


# *******************
# *		SETUPS		*
# *******************

#setup every L2 contract
setupEveryL2Contracts:
	bash script/shell/setups/L2setups/setupEveryL2Contracts.sh


# **************************************
# *		Config L1 and L1     *
# **************************************
setupEveryContracts:
	bash script/shell/updateL1L2Configuration.sh
	if [ -d marker ]; then rm -rf marker; fi
	bash script/configure.sh


	