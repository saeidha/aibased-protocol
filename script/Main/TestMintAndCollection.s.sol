// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol"; // Import the Vm type to access Vm.Log
import {AIBasedNFTFactory} from "../../src/AIBasedNFTFactory.sol";
import {NFTCollection} from "../../src/NFTCollection.sol"; // We need this to interact with the created collections
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
contract TestMintAndCollection is Script {
    // --- State Variables for the Script ---
    AIBasedNFTFactory factory;
    uint256 creatorPrivateKey;

    // --- Setup Function (Runs once before tests) ---
    function setUp() public {
        // Load all addresses and keys from .env file
        factory = AIBasedNFTFactory(vm.envAddress("FACTORY_ADDRESS"));
        creatorPrivateKey = vm.envUint("PRIVATE_KEY");

        // When running on a live network with --broadcast, vm.deal() has no effect.
        // Ensure the collectionCreator wallet has enough native currency (e.g., ETH)
        // to pay for the gas fees for all transactions.
    }

    // --- Main Run Function ---
    function run() public {
        
        createMintAndVerify();
    }



    function createMintAndVerify() public {
    // Setup contract config
    string memory name = "NewSAEIDInstant Mint Collection";
    string memory description = "NewSAEIDA collection with an immediate mint.";
    string memory model = "v2";
    string memory style = "Drawing";
    string memory symbol = "NSMT";
    string memory baseURI = "ipfs://bafkreihgfshpecp7w5rzh56ooq5gjg5jqdcxrtowmsv2tfc4dxi2f45wn4";
    
    vm.recordLogs();
    vm.startBroadcast(creatorPrivateKey);
    
    factory.createAndMint{value: 0.000001 ether}(
        name,
        description,
        model,
        style,
        symbol,
        baseURI
    );

    vm.stopBroadcast();

    // // Get collection address from logs
    // Vm.Log[] memory entries = vm.getRecordedLogs();
    // address newCollectionAddress;

    // for (uint i = 0; i < entries.length; i++) {
    //     if (entries[i].topics[0] == AIBasedNFTFactory.CollectionCreated.selector) {
    //         newCollectionAddress = address(uint160(uint256(entries[i].topics[1])));
    //         break;
    //     }
    // }
    
    // require(newCollectionAddress != address(0), "Could not find new collection address from events");
    // console.log("New collection deployed at:", newCollectionAddress);

    // // Build verification command in parts
    //    string memory command = string.concat(
    //     "forge verify-contract ",
    //     Strings.toHexString(uint160(newCollectionAddress), 20),
    //     " NFTCollection",
    //     " --chain-id 84532",
    //     " --constructor-args \""
    // );

    // string memory constructorArgs = string.concat(
    //     "$(cast abi-encode 'constructor((string,string,string,string,string,uint256,uint256,string,bool,uint256,address,address,address))' '(",
    //     "\"", name, "\",",
    //     "\"", description, "\",",
    //     "\"", model, "\",",
    //     "\"", style, "\",",
    //     "\"", symbol, "\",",
    //     "1,",
    //     Strings.toString(block.timestamp + 1 hours), ",", // Fix: Use correct timestamp
    //     "\"", baseURI, "\",",
    //     "true,0,",
    //     "\"", Strings.toHexString(uint160(factory.owner()), 20), "\",",
    //     "\"", Strings.toHexString(uint160(collectionCreator), 20), "\",",
    //     "\"", Strings.toHexString(uint160(address(factory)), 20), "\"",
    //     ")')"
    // );

    // string memory flags = string.concat(
    //     "\" --verifier-url https://api-sepolia.basescan.org/api",
    //     " --etherscan-api-key $ETHERSCAN_API_KEY"
    // );

    // console.log("\nTo verify the contract, run:");
    // console.log("----------------------------------");
    // console.log(string.concat(command, constructorArgs, flags));
    }
}
