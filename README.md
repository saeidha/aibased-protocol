ABI:


forge inspect src/AIBasedNFTFactory.sol:AIBasedNFTFactory abi --json > AIBasedNFTFactory.json

forge inspect src/NFTCollection.sol:NFTCollection abi --json > NFTCollection.json

forge inspect src/LevelNFTCollection.sol:LevelNFTCollection abi --json > LevelNFTCollection.json

forge inspect src/W3PASS.sol:W3PASS abi --json > W3PASS.json



Deply FACTROY TESTNET:

forge script script/DeployFactorySepolia.s.sol:DeployFactory --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv

SET FEE:
forge script script/SetFeeSepolia.s.sol:SetFee --rpc-url $RPC_URL_SEPOLIA --broadcast --with-gas-price 100000000000000 -- -- 0.05e18


TEST MINT AND CREATE COLLECTION:

forge script script/TestMintAndCollectionSepolia.s.sol:TestMintAndCollection --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv

TEST FEE:

forge script script/TestFeesSepolia.s.sol:TestFees --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv


DEPLOY LEVEL:

forge script script/DeployAndLinkLevelNFTSepolia.s.sol:DeployAndLinkLevelNFT --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv


TEST MINT LEVEL:

forge script script/TestMintLevelSepolia.s.sol:MintLevel --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv


DEPLOY W3PASS:
forge script script/DeployW3PassSepolia.s.sol:DeployW3Pass --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv

TEST MINT W3PASS:

forge script script/TestMintW3PassSepolia.s.sol:TestMintW3Pass --rpc-url $RPC_URL_SEPOLIA --broadcast  -vvvv