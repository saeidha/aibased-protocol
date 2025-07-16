Deply FACTROY TESTNET:

forge script script/DeployFactorySepolia.s.sol:DeployFactory --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv



DEPLOY LEVEL:

forge script script/DeployAndLinkLevelNFTSepolia.s.sol:DeployAndLinkLevelNFT --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv


TEST MINT:

forge script script/TestMintLevelSepolia.s.sol:MintLevel --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv