// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AIBasedNFTFactory} from "../src/AIBasedNFTFactory.sol";
import {W3PASS} from "../src/W3PASS.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TestMintW3Pass is Script {
    using ECDSA for bytes32;

    // --- State Variables for the Script ---
    AIBasedNFTFactory factory;
    W3PASS w3pass;
    address minter;
    uint256 minterPrivateKey;
    address anotherMinter;
    uint256 anotherMinterPrivateKey;
    uint256 authorizerPrivateKey;
    

    // --- Test Configuration ---
    uint256 constant DISCOUNT_TIER = 3;

    // --- Setup Function (Runs once before tests) ---
    function setUp() public {
        // Load all addresses and keys from .env file
        factory = AIBasedNFTFactory(vm.envAddress("FACTORY_ADDRESS_SEPOLIA"));
        w3pass = W3PASS(vm.envAddress("W3PASS_ADDRESS_SEPOLIA"));
        minter = vm.envAddress("MINTER_ADDRESS_SEPOLIA");
        minterPrivateKey = vm.envUint("MINTER_ADDRESS_KEY_SEPOLIA");
        authorizerPrivateKey = vm.envUint("AUTHORIZER_PRIVATE_KEY_SEPOLIA");
        anotherMinter = vm.envAddress("ANOTHER_INVALID_MINTER_ADDRESS_SEPOLIA");
        anotherMinterPrivateKey = vm.envUint("ANOTHER_INVALID_MINTER_ADDRESS_KEY_SEPOLIA");
    }

    // --- Main Run Function ---
    // function run() public {
    //     console.log("--- Testing Mint with Discount for:", minter, "---");

    //     // --- 1. DEBUGGING: Verify contract and state ---
    //     console.log("Verifying contract existence at:", address(w3pass));
    //     if (address(w3pass).code.length == 0) {
    //         revert("W3PASS contract not found at the specified address! Please check W3PASS_ADDRESS_SEPOLIA in your .env file.");
    //     }
    //     console.log("Contract code found. Reading basePrice...");
    //     uint256 currentBasePrice = w3pass.basePrice();
    //     console.log("On-Chain Base Price:", currentBasePrice);

    //     // --- 2. Get Required Data ---
    //     uint256 price = w3pass.getPrice(DISCOUNT_TIER);
    //     bytes32 onChainMerkleRoot = w3pass.merkleRoot();
        
    //     // --- 3. Generate Signature ---
    //     bytes32 messageHash = keccak256(abi.encodePacked(minter));
    //     bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorizerPrivateKey, ethSignedMessageHash);
    //     bytes memory signature = abi.encodePacked(r, s, v);

    //     console.log("Signature:");
    //     console.logBytes(signature);
    //     // --- 4. Define the Merkle Proof ---
    //     // IMPORTANT: This proof MUST be for the 'minter' address and 'DISCOUNT_TIER'.
    //     // Get this from your Rust backend for the specific user.
    //     bytes32[] memory merkleProof = new bytes32[](1);
    //     merkleProof[0] = 0xca601830424de88ff4468f7a6f2041323386f43653145a3884334346452f1040;

    //     // --- 5. DEBUGGING STEP: Verify the proof inside the script ---
    //     bytes32 leaf = keccak256(abi.encodePacked(minter, DISCOUNT_TIER));
    //     bool isProofValid = MerkleProof.verify(merkleProof, onChainMerkleRoot, leaf);
        
    //     console.log("On-Chain Merkle Root:");
    //     console.logBytes32(onChainMerkleRoot);

    //     console.log("Calculated Leaf Hash:");
    //     console.logBytes32(leaf);
    //     console.log("Is Proof Valid? ->", isProofValid);

    //     // This check will fail the script here if the proof is bad, giving a clear error.
    //     require(isProofValid, "Merkle Proof Verification FAILED inside the script!");

    //     // --- 6. Broadcast the Transaction ---
    //     console.log("\nAttempting to broadcast transaction...");
    //     console.log("Balance before:", minter.balance);

    //     vm.startBroadcast(minterPrivateKey);
    //     factory.mintW3Pass{value: price}(DISCOUNT_TIER, merkleProof, signature);
    //     vm.stopBroadcast();

    //     console.log("Mint with discount successful!");
    //     console.log("Balance after:", minter.balance);
    //     console.log("NFTs owned:", w3pass.balanceOf(minter));
    // }


    // --- Main Run Function ---
    function run() public {
        console.log("--- Testing Mint with Discount for:", anotherMinter, "---");

        // --- 1. DEBUGGING: Verify contract and state ---
        console.log("Verifying contract existence at:", address(w3pass));
        if (address(w3pass).code.length == 0) {
            revert("W3PASS contract not found at the specified address! Please check W3PASS_ADDRESS_SEPOLIA in your .env file.");
        }
        console.log("Contract code found. Reading basePrice...");
        uint256 currentBasePrice = w3pass.basePrice();
        console.log("On-Chain Base Price:", currentBasePrice);

        // --- 2. Get Required Data ---
        uint256 price = w3pass.getPrice(DISCOUNT_TIER);
        bytes32 onChainMerkleRoot = w3pass.merkleRoot();
        
        // --- 3. Generate Signature ---
        bytes32 messageHash = keccak256(abi.encodePacked(anotherMinter));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorizerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        console.log("Signature:");
        console.logBytes(signature);
        // --- 4. Define the Merkle Proof ---
        // IMPORTANT: This proof MUST be for the 'anotherMinter' address and 'DISCOUNT_TIER'.
        // Get this from your Rust backend for the specific user.
        // --- Merkle Proof is an empty array for public mint ---
        // bytes32[] memory merkleProof = new bytes32[](0);
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = 0x0fc848d505c80488eb6c0ff72af5476b293a59b05b1f1e15459325653158c2ad;

        // --- 5. DEBUGGING STEP: Verify the proof inside the script ---
        bytes32 leaf = keccak256(abi.encodePacked(anotherMinter, DISCOUNT_TIER));
        bool isProofValid = MerkleProof.verify(merkleProof, onChainMerkleRoot, leaf);

        console.log("Discount_TIER:", DISCOUNT_TIER);

        console.log("On-Chain Merkle Root:");
        console.logBytes32(onChainMerkleRoot);

        console.log("Calculated Leaf Hash:");
        console.logBytes32(leaf);
        console.log("Is Proof Valid? ->", isProofValid);

        // This check will fail the script here if the proof is bad, giving a clear error.
        require(isProofValid, "Merkle Proof Verification FAILED inside the script!");

        // --- 6. Broadcast the Transaction ---
        console.log("\nAttempting to broadcast transaction...");
        console.log("Balance before:", anotherMinter.balance);


        vm.startBroadcast(anotherMinterPrivateKey);
        factory.mintW3Pass{value: price}(DISCOUNT_TIER, merkleProof, signature);
        vm.stopBroadcast();

        console.log("Mint with discount successful!");
        console.log("Balance after:", anotherMinter.balance);
        console.log("NFTs owned:", w3pass.balanceOf(anotherMinter));
    }
}