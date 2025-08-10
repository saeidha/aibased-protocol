// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LevelNFTCollection} from "../../src/LevelNFTCollection.sol";

/**
 * @title SetW3PassBasePrice
 * @notice A script to update the Merkle Root on the W3PASS contract.
 * @dev This should be run by the owner of the W3PASS contract.
 */
contract SetFactoryAddressForLevel is Script {

    function run() public {

         // --- 1. Load All Configuration ---
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        address levelNftAddress = vm.envAddress("LEVEL_NFT_COLLECTION");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Validate that environment variables are set
        require(factoryAddress != address(0), "FACTORY_ADDRESS not set in .env");
        require(levelNftAddress != address(0), "LEVEL_NFT_COLLECTION not set in .env");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set in .env");

        // --- 2. Deployment and Linking ---
        vm.startBroadcast(deployerPrivateKey);

        LevelNFTCollection levelCollection = LevelNFTCollection(levelNftAddress);

        // Configure the factory to link it to the new LevelNFTCollection
        console.log("Setting factory for Level NFT Collection ...");
        levelCollection.setFactoryAddress(factoryAddress);

        vm.stopBroadcast();
    }
}
