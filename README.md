ABI:


forge inspect src/AIBasedNFTFactory.sol:AIBasedNFTFactory abi --json > AIBasedNFTFactory.json

forge inspect src/NFTCollection.sol:NFTCollection abi --json > NFTCollection.json

forge inspect src/LevelNFTCollection.sol:LevelNFTCollection abi --json > LevelNFTCollection.json

forge inspect src/W3PASS.sol:W3PASS abi --json > W3PASS.json



Deply FACTROY TESTNET:

forge script script/DeployFactorySepolia.s.sol:DeployFactory --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv

SET FEE:
forge script script/SetFeeSepolia.s.sol:SetFee --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv


TEST MINT AND CREATE COLLECTION:

forge script script/TestMintAndCollectionSepolia.s.sol:TestMintAndCollection --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv

TEST FEE:

forge script script/TestFeesSepolia.s.sol:PayFee --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv


DEPLOY LEVEL:

forge script script/DeployAndLinkLevelNFTSepolia.s.sol:DeployAndLinkLevelNFT --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv


TEST MINT LEVEL:

forge script script/TestMintLevelSepolia.s.sol:MintLevel --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv


DEPLOY W3PASS:
forge script script/DeployW3PassSepolia.s.sol:DeployW3Pass --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv


SET MARKLET ROOT:

forge script script/SetMerkleRootSepolia.s.sol:SetMerkleRoot --rpc-url $RPC_URL_SEPOLIA --broadcast  -vvvv


TEST MINT W3PASS:

forge script script/TestMintW3PassSepolia.s.sol:TestMintW3Pass --rpc-url $RPC_URL_SEPOLIA --broadcast  -vvvv


ExampleLog: 
forge script script/example/SignAndVerifyScript.s.sol:SignAndVerifyScript --rpc-url $RPC_URL_SEPOLIA --broadcast  -vvvv


TEST CHANGE FEE:

forge script script/TestFeeLogicSepolia.s.sol:TestFeeLogic --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv






////////TEST MAIN


Deply FACTROY:

forge script script/Main/DeployFactory.s.sol:DeployFactory --rpc-url $RPC_URL --broadcast --verify -vvvv


DEPLOY LEVEL:

forge script script/Main/DeployAndLinkLevelNFT.s.sol:DeployAndLinkLevelNFT --rpc-url $RPC_URL --broadcast --verify -vvvv

DEPLOY W3PASS:

forge script script/Main/DeployW3Pass.s.sol:DeployW3Pass --rpc-url $RPC_URL --broadcast --verify -vvvv

TEST MINT W3PASS:

forge script script/Main/TestMintW3Pass.s.sol:TestMintW3Pass --rpc-url $RPC_URL --broadcast --verify -vvvv


SET W3Pass New Price:

forge script script/Main/SetW3PassBasePrice.s.sol:SetW3PassBasePrice --rpc-url $RPC_URL --broadcast  -vvvv


DEPLOY LEVEL:

forge script script/Main/SetFactoryAddressForLevel.s.sol:SetFactoryAddressForLevel --rpc-url $RPC_URL --broadcast --verify -vvvv



forge script script/Main/SetW3PassInFactory.s.sol:SetW3PassInFactory --rpc-url $RPC_URL --broadcast --verify -vvvv
<!-- TEST MINT AND CREATE COLLECTION:

forge script script/Main/TestMintAndCollection.s.sol:TestMintAndCollection --rpc-url $RPC_URL --broadcast --verify -vvvv -->
