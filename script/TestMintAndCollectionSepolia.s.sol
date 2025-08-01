// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol"; // Import the Vm type to access Vm.Log
import {AIBasedNFTFactory} from "../src/AIBasedNFTFactory.sol";
import {NFTCollection} from "../src/NFTCollection.sol"; // We need this to interact with the created collections

contract TestMintAndCollection is Script {
    // --- State Variables for the Script ---
    AIBasedNFTFactory factory;
    address collectionCreator;
    uint256 creatorPrivateKey;

    // --- Setup Function (Runs once before tests) ---
    function setUp() public {
        // Load all addresses and keys from .env file
        factory = AIBasedNFTFactory(vm.envAddress("FACTORY_ADDRESS_SEPOLIA"));
        collectionCreator = vm.envAddress("ANOTHER_INVALID_MINTER_ADDRESS_SEPOLIA");
        creatorPrivateKey = vm.envUint("ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA");

        // When running on a live network with --broadcast, vm.deal() has no effect.
        // Ensure the collectionCreator wallet has enough native currency (e.g., ETH)
        // to pay for the gas fees for all transactions.
    }

    // --- Main Run Function ---
    function run() public {
        test_createCollection();
        test_createAndMint();
        test_mintFromExistingCollection();
    }

    // --- Test Case 1: Creating a new collection ---
    function test_createCollection() public {
        console.log("\n---Testing createCollection ---");
        
        vm.startBroadcast(creatorPrivateKey);

        address newCollectionAddress = factory.createCollection(
            "NewSAEID Test Collection",
            "NewSAEID collection created for testing.",
            "model-x",
            "style-y",
            "TEST",
            "bafkreigllqqwui2rfhz6smd6m2efhclvzwtybrlfjibwj6b43vvbhi4tyi",
            100,
            block.timestamp + 1 days,
            false,
            0.00001 ether,
            false,
            false
        );

        vm.stopBroadcast();

        require(newCollectionAddress != address(0), "createCollection returned a zero address");
        console.log("createCollection successful. New Collection at:", newCollectionAddress);
    }

    // --- Test Case 2: Creating a collection and minting immediately ---
    function test_createAndMint() public {
        console.log("\n--- Testing createAndMint ---");

        // Start recording logs to capture the event data
        vm.recordLogs();
        
        vm.startBroadcast(creatorPrivateKey);
        factory.createAndMint{value: 0.0001 ether}(
            "NewSAEIDInstant Mint Collection",
            "NewSAEIDA collection with an immediate mint.",
            "model-instant",
            "style-now",
            "INST",
            "bafkreigllqqwui2rfhz6smd6m2efhclvzwtybrlfjibwj6b43vvbhi4tyi"
        );
        vm.stopBroadcast();

        // Get all logs emitted during the transaction
        Vm.Log[] memory entries = vm.getRecordedLogs();
        address newCollectionAddress;

        // --- FIX: Parse the indexed 'collection' address from topics ---
        // This is more efficient and correct, and it avoids the "Stack too deep" error.
        for (uint i = 0; i < entries.length; i++) {
            // The first topic is the event signature hash. The second topic is the first indexed argument.
            if (entries[i].topics[0] == AIBasedNFTFactory.CollectionCreated.selector) {
                // The 'collection' address is indexed, so it's in the topics array.
                // We cast the bytes32 topic to an address.
                newCollectionAddress = address(uint160(uint256(entries[i].topics[1])));
                break;
            }
        }
        
        require(newCollectionAddress != address(0), "Could not find new collection address from events");
        console.log("Found new collection at:", newCollectionAddress);

        NFTCollection newCollection = NFTCollection(newCollectionAddress);
        uint256 creatorBalance = newCollection.balanceOf(collectionCreator);

        require(creatorBalance == 1, "Creator should own 1 NFT after createAndMint");
        console.log("createAndMint successful. Creator balance:", creatorBalance);
    }

    // --- Test Case 3: Minting from a collection that already exists ---
    function test_mintFromExistingCollection() public {
        console.log("\n--- Testing mintNFT from an existing collection ---");

        // Step A: First, create a collection to mint from
        vm.startBroadcast(creatorPrivateKey);
        address collectionToMintFrom = factory.createCollection(
            "NewSAEIDExisting Collection", "For mintNFT test", "model-e", "style-f", "EXIST", "bafkreigllqqwui2rfhz6smd6m2efhclvzwtybrlfjibwj6b43vvbhi4tyi", 100, block.timestamp + 1 days, false, 0.0001 ether, false, false
        );
        vm.stopBroadcast();
        
        require(collectionToMintFrom != address(0), "Failed to create collection for mintNFT test");
        console.log("Created collection to mint from at:", collectionToMintFrom);

        NFTCollection existingCollection = NFTCollection(collectionToMintFrom);
        console.log("Balance before mint:", existingCollection.balanceOf(collectionCreator));

        // Step B: Now, mint from that collection
        vm.startBroadcast(creatorPrivateKey);
        factory.mintNFT{value: 0.00011 ether}(collectionToMintFrom, collectionCreator, 1);
        vm.stopBroadcast();

        uint256 finalBalance = existingCollection.balanceOf(collectionCreator);
        require(finalBalance > 0, "Balance should be greater than 0 after minting");
        console.log("mintNFT successful. Final balance:", finalBalance);
    }
}
