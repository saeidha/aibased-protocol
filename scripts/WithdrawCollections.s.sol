// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/NFTFactory.sol";
import "../src/NFTCollection.sol";

contract WithdrawCollections is Script {
    function run() external {
        // Get private key from env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Factory address
        address factoryAddress = 0x8e49aD54352E8658a7EBb8e6B22A33299832F27D;
        NFTFactory factory = NFTFactory(factoryAddress);

        // Get all collections
        address[] memory collections = factory.getCollections();
        console.log("Found %d collections", collections.length);

        // Process each collection
        for (uint256 i = 0; i < collections.length; i++) {
            address collectionAddress = collections[i];
            NFTCollection collection = NFTCollection(collectionAddress);
            
            // Check if we are the owner
            if (collection.owner() == vm.addr(deployerPrivateKey)) {
                uint256 balance = address(collection).balance;
                if (balance > 0) {
                    console.log("Withdrawing from collection %s, balance: %d", collectionAddress, balance);
                    collection.withdraw();
                } else {
                    console.log("Collection %s has no balance", collectionAddress);
                }
            } else {
                console.log("Not owner of collection %s", collectionAddress);
            }
        }

        vm.stopBroadcast();
    }
} 