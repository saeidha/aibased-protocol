// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AIBasedNFTFactory} from "../src/AIBasedNFTFactory.sol";
import {LevelNFTCollection} from "../src/LevelNFTCollection.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MintLevel is Script {
    using ECDSA for bytes32;
    function run() public {
        // --- 1. Load Configuration ---
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS_SEPOLIA");
        address levelNftAddress = vm.envAddress("LEVEL_NFT_COLLECTION_SEPOLIA"); // You'll need to add this
        uint256 authorizerPrivateKey = vm.envUint("AUTHORIZER_PRIVATE_KEY_SEPOLIA"); // You'll need to add this
        address minter = vm.envAddress("MINTER_ADDRESS_SEPOLIA"); // The user who will receive the NFT
        uint256 minterPrivateKey = vm.envUint("MINTER_ADDRESS_KEY_SEPOLIA"); // The user who will receive the NFT

        // Validate configuration
        require(factoryAddress != address(0), "FACTORY_ADDRESS_SEPOLIA not set");
        require(levelNftAddress != address(0), "LEVEL_NFT_ADDRESS_SEPOLIA not set");
        require(authorizerPrivateKey != 0, "AUTHORIZER_PRIVATE_KEY not set");
        require(minter != address(0), "MINTER_ADDRESS not set");
        require(minterPrivateKey != 0, "MINTER_ADDRESS_KEY not set");

        // --- 2. Load Contracts ---
        

        // The level we want to test minting for
        uint256 levelToMint = 5;

        // --- 2. Simulate Backend: Create the Signature ---
        bytes32 messageHash = keccak256(abi.encodePacked(minter, levelToMint));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorizerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // --- 3. Simulate User: Call the Mint Function ---
        AIBasedNFTFactory factory = AIBasedNFTFactory(factoryAddress);
        
        console.log("Attempting to mint Level", levelToMint, "for user", minter);

        // Impersonate the minter to call the function
        vm.startBroadcast(minterPrivateKey);
        factory.mintLevelNFT(levelToMint, signature);

        console.log("Mint simulation successful!");
        
        // --- 4. Verify the Result ---
        LevelNFTCollection levelNft = LevelNFTCollection(levelNftAddress);
        console.log("Minter's new balance:", levelNft.balanceOf(minter));
        console.log("Token owner of ID 0:", levelNft.ownerOf(0));

        vm.stopBroadcast();
    }
}