## Twine Smart Contracts

## Overview
Twine Chain is a multi-chain settlement network designed to aggregate chains and provide seamless cross-chain liquidity access. This repository contains the bridge contract for Twine on the Solana blockchain.

## Setup and Deployment Instructions
### 1. General Setup
-  **Makefile Usage:**  

    >All building, deployment, and setup operations can be executed through the Makefile.
    - **List Available Commands:** 
        - make help

- **General Configuration:**
    > Set L1 and L2 private key and rpc

    - **L1 Setup**

        make updateL1DefaultValues  
    - **L2 Setup**

        make updateL2DefaultValues  

### 2. Deployment and Setup Commands

- **Fresh Deployment and Setup:**  
    - make clean
    - make build
    - **Deploy and setup both L1 and L2(Twine chain) contracts**
        - make setupEveryContracts
    - **Deploy and setup  L1 contracts**
        - make deployEveryL1Contracts
        - make setupEveryL1Contracts
    
    - **Deploy and setup  L2 contracts**
        - make deployEveryL2Contracts
        - make setupEveryL2Contracts

### 3. Token Operations
#### A. Native Token Deposit
- **Deposit ERC20**
    - make deposit-native-token
- **Forced Withdrawal**
    - make forcedWithdrawETH 

#### B.ERC20 Token Deposit
- **Update Token Mapping (if not already set):**
    - make updateTokenMappingCG
- **Deposit ERC20**
   - make depositERC20
- **Forced Withdrawal**
    - make forcedWithdrawERC20 

### 4. Steps to interact with deployed contracts
 - List Available Commands:
- Update contract addresses in deployedContracts.json
- Set L1 and L2 private key and rpc
    - make updateL1DefaultValues 
    - make updateL2DefaultValues

- Use make command to interact with contracts
     -  make help




