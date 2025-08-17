# AI-Based NFT Creator Factory and W3Pass

This project contains the smart contracts for an NFT creator factory and the W3Pass NFT logic. It's the core of the full aibased.app experience, enabling users to earn XP, level up, claim rewards, mint NFTs, and access premium tools.

## ⚠️ License

This project is private and proprietary to aibased.app. All rights are reserved. The code is for internal use by aibased.app developers and is not licensed for any other use, distribution, or modification.

**Copyright (c) 2024 aibased.app**

All rights reserved.

This software is the confidential and proprietary information of aibased.app ("Confidential Information"). You shall not disclose such Confidential Information and shall use it only in accordance with the terms of the license agreement you entered into with aibased.app.

---

## Deploy Commands

### ABI Generation

Use these commands to generate the necessary ABI files for each smart contract.

* `forge inspect src/AIBasedNFTFactory.sol:AIBasedNFTFactory abi --json > AIBasedNFTFactory.json`
* `forge inspect src/NFTCollection.sol:NFTCollection abi --json > NFTCollection.json`
* `forge inspect src/LevelNFTCollection.sol:LevelNFTCollection abi --json > LevelNFTCollection.json`
* `forge inspect src/W3PASS.sol:W3PASS abi --json > W3PASS.json`

### Testnet (Sepolia) Deployment

These commands are for deploying and testing the contracts on the Sepolia testnet.

#### Factory and Fees
* **Deploy Factory:** `forge script script/DeployFactorySepolia.s.sol:DeployFactory --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv`
* **Set Fee:** `forge script script/SetFeeSepolia.s.sol:SetFee --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv`
* **Test Mint and Create Collection:** `forge script script/TestMintAndCollectionSepolia.s.sol:TestMintAndCollection --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv`
* **Test Fee Payment:** `forge script script/TestFeesSepolia.s.sol:PayFee --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv`
* **Test Change Fee:** `forge script script/TestFeeLogicSepolia.s.sol:TestFeeLogic --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv`

#### Level and W3Pass
* **Deploy Level NFT:** `forge script script/DeployAndLinkLevelNFTSepolia.s.sol:DeployAndLinkLevelNFT --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv`
* **Test Mint Level:** `forge script script/TestMintLevelSepolia.s.sol:MintLevel --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv`
* **Deploy W3Pass:** `forge script script/DeployW3PassSepolia.s.sol:DeployW3Pass --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv`
* **Set Merkle Root:** `forge script script/SetMerkleRootSepolia.s.sol:SetMerkleRoot --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv`
* **Test Mint W3Pass:** `forge script script/TestMintW3PassSepolia.s.sol:TestMintW3Pass --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv`

#### Example
* **Log Example:** `forge script script/example/SignAndVerifyScript.s.sol:SignAndVerifyScript --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv`

### Mainnet Deployment

These commands are for deploying the contracts on the Ethereum mainnet.

#### Initial Deployment
* **Deploy Factory:** `forge script script/Main/DeployFactory.s.sol:DeployFactory --rpc-url $RPC_URL --broadcast --verify -vvvv`
* **Deploy Level NFT:** `forge script script/Main/DeployAndLinkLevelNFT.s.sol:DeployAndLinkLevelNFT --rpc-url $RPC_URL --broadcast --verify -vvvv`
* **Deploy W3Pass:** `forge script script/Main/DeployW3Pass.s.sol:DeployW3Pass --rpc-url $RPC_URL --broadcast --verify -vvvv`
* **Set W3Pass Price:** `forge script script/Main/SetW3PassBasePrice.s.sol:SetW3PassBasePrice --rpc-url $RPC_URL --broadcast -vvvv`
* **Set Level in Factory:** `forge script script/Main/SetFactoryAddressForLevel.s.sol:SetFactoryAddressForLevel --rpc-url $RPC_URL --broadcast --verify -vvvv`
* **Set W3Pass in Factory:** `forge script script/Main/SetW3PassInFactory.s.sol:SetW3PassInFactory --rpc-url $RPC_URL --broadcast --verify -vvvv`
* **Deploy AIBasedBadge:** `forge script script/Main/DeployAIBasedBadge.s.sol:DeployAIBasedBadge --rpc-url $RPC_URL --broadcast --verify -vvvv`

#### Factory Redeployment Flow
Follow these steps to redeploy the factory and relink all dependencies.
1.  **Redeploy Factory:** `forge script script/Main/ReDeployFactory.s.sol:DeployFactory --rpc-url $RPC_URL --broadcast --verify -vvvv`
2.  **Set Factory in Level NFT:** `forge script script/Main/SetFactoryAddressForLevel.s.sol:SetFactoryAddressForLevel --rpc-url $RPC_URL --broadcast --verify -vvvv`
3.  **Set Factory in W3Pass:** `forge script script/Main/SetW3PassInFactory.s.s.sol:SetW3PassInFactory --rpc-url $RPC_URL --broadcast --verify -vvvv`
4.  **Deploy AIBasedBadge:** `forge script script/Main/DeployAIBasedBadge.s.sol:DeployAIBasedBadge --rpc-url $RPC_URL --broadcast --verify -vvvv`