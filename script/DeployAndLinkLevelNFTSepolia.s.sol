// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
// We need the interface to call the factory's functions
import {AIBasedNFTFactory} from "../src/AIBasedNFTFactory.sol";
import {LevelNFTCollection} from "../src/LevelNFTCollection.sol";
import "forge-std/console.sol";

contract DeployAndLinkLevelNFT is Script {
    function run() public returns (LevelNFTCollection) {
        // --- 1. Load All Configuration ---
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS_SEPOLIA");
        address authorizer = vm.envAddress("AUTHORIZER_ADDRESS_SEPOLIA");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        string memory ipfsBaseURI = vm.envString("LEVEL_IPFS_BASE_URI");

        // Validate that environment variables are set
        require(factoryAddress != address(0), "FACTORY_ADDRESS_SEPOLIA not set in .env");
        require(authorizer != address(0), "AUTHORIZER_ADDRESS_SEPOLIA not set in .env");
        require(bytes(ipfsBaseURI).length > 0, "IPFS_BASE_URI_SEPOLIA not set in .env");
        require(deployerPrivateKey != 0, "PRIVATE_KEY_SEPOLIA not set in .env");

        // --- 2. Deployment and Linking ---
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the LevelNFTCollection, passing the existing factory address
        LevelNFTCollection levelNft = new LevelNFTCollection(factoryAddress, ipfsBaseURI);
        console.log("LevelNFTCollection deployed at:", address(levelNft));

        // Get a reference to the already deployed factory contract
        AIBasedNFTFactory factory = AIBasedNFTFactory(factoryAddress);

        // Configure the factory to link it to the new LevelNFTCollection
        console.log("Setting Level NFT Collection on the factory...");
        factory.setLevelNFTCollection(address(levelNft));

        console.log("Setting Authorizer on the factory...");
        factory.setAuthorizer(authorizer);

        vm.stopBroadcast();

        console.log("System fully deployed and linked!");
        return levelNft;
    }
}