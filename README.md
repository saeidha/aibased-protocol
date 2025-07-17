Deply FACTROY TESTNET:

forge script script/DeployFactorySepolia.s.sol:DeployFactory --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv



DEPLOY LEVEL:

forge script script/DeployAndLinkLevelNFTSepolia.s.sol:DeployAndLinkLevelNFT --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv


TEST MINT LEVEL:

forge script script/TestMintLevelSepolia.s.sol:MintLevel --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv


DEPLOY W3PASS:
forge script script/DeployW3PassSepolia.s.sol:DeployW3Pass --rpc-url $RPC_URL_SEPOLIA --broadcast --verify -vvvv

TEST MINT W3PASS:

forge script script/TestMintW3PassSepolia.s.sol:TestMintW3Pass --rpc-url $RPC_URL_SEPOLIA -vvvv