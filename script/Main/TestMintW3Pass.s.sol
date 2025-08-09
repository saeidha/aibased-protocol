// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AIBasedNFTFactory} from "../../src/AIBasedNFTFactory.sol";
import {W3PASS} from "../../src/W3PASS.sol";
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
    // address anotherMinter;
    // uint256 anotherMinterPrivateKey;
    // uint256 authorizerPrivateKey;
    bytes32 merkleRoot;

    // --- Test Configuration ---
    uint256 constant DISCOUNT_TIER = 3;

    // --- Setup Function (Runs once before tests) ---
    function setUp() public {
        // Load all addresses and keys from .env file
        factory = AIBasedNFTFactory(vm.envAddress("FACTORY_ADDRESS"));
        w3pass = W3PASS(vm.envAddress("W3PASS_ADDRESS"));
        minter = vm.envAddress("ANOTHER_INVALID_MINTER_ADDRESS_SEPOLIA");
        minterPrivateKey = vm.envUint("ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA");
        // authorizerPrivateKey = vm.envUint("AUTHORIZER_PRIVATE_KEY");

        merkleRoot = vm.envBytes32("INITIAL_MERKLE_ROOT");
    }

    // --- Main Run Function ---
    function run() public {
        console.log("--- Testing Mint with Discount for:", minter, "---");

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
        console.log("Price:", price);
        bytes32 onChainMerkleRoot = w3pass.merkleRoot();
        
        // --- 3. Generate Signature ---
        // bytes32 messageHash = keccak256(abi.encodePacked(anotherMinter));
        // bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorizerPrivateKey, ethSignedMessageHash);
        // bytes memory signature = abi.encodePacked(r, s, v);

        // console.log("Signature:");
        // console.logBytes(signature);
        bytes memory signature = hex"8c06b21d60440befa764a9c77da6bfacb0fbf4a64fff6a42ae686580cebcafd8692c1d0dc21c471fadb7345056d78f9ab817c0e6d4e288d083ff4e41a140ba311b";
        // --- 4. Define the Merkle Proof ---
        // IMPORTANT: This proof MUST be for the 'anotherMinter' address and 'DISCOUNT_TIER'.
        // Get this from your Rust backend for the specific user.
        // --- Merkle Proof is an empty array for public mint ---
        // bytes32[] memory merkleProof = new bytes32[](0);
        bytes32[] memory merkleProof = new bytes32[](14);

            merkleProof[0] = hex"6122e8fc24eb440db58a2a137431c6fe26850bb8e16ea82daf6dba59167fa4e6";
            merkleProof[1] = hex"bf0ee62e6749a4479d285a3b34698c3976087420e29afc854967c4f7ca18a4fb";
            merkleProof[2] = hex"cb36d995d104144b0156dc3c141cc984c065a167944951c2a8c6d76be69efe44";
            merkleProof[3] = hex"6f88ef0021833dd74d8287b671a23d5e32cc5220469a7bd49d7cc085827ca4b7";
            merkleProof[4] = hex"81a89b8d98b7dabb95f8adf7cd2882e36d870caf455a116566553d5911d7efc2";
            merkleProof[5] = hex"58b3e92f91c6ea47609b9c4cfc6513c242ef51edba110c21bb2fb0a9fc8ec6cf";
            merkleProof[6] = hex"286fe256082518a0d74428ae274adc9905f1c3535ead60b0996e32ab814bd686";
            merkleProof[7] = hex"8922238ad579d8514dbb8273098c260b8bec502b7b34b69d60d20f8b5e151505";
            merkleProof[8] = hex"bd8a79c2fe141f22f3520d4674531b08a1442a3287d9b082f6d811cc3a31ab01";
            merkleProof[9] = hex"3ab9b504baa24acf54deb1b6602219d8d9070d818de4f3cc27cc10da995ae21e";
            merkleProof[10] = hex"5b8630f6e3a8503a74b645db04afc60a1f55230e7fd92f43811d8c4b4ab6ef61";
            merkleProof[11] = hex"db82eb652bd02e734870e37a48edd04f5e2236089fe536f50ff4e93ef81d3206";
            merkleProof[12] = hex"5999fcfbbe5cdf401ded7566559e961e4277f179f6e0388e737ebc413ce8d849";
            merkleProof[13] = hex"7befa581992fda276bc8faeb38379482838a8543753287d355c8a8c1a4ba81f3";







        // merkleProof[3] = hex"7fcec138428656da300294c921872fc080c011220e85ec1f83abe12e17584251";
        // --- 5. DEBUGGING STEP: Verify the proof inside the script ---
        bytes32 leaf = keccak256(abi.encodePacked(minter, DISCOUNT_TIER));
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
        console.log("Balance before:", minter.balance);


        vm.startBroadcast(minterPrivateKey);
        factory.mintW3Pass{value: price}(DISCOUNT_TIER, merkleProof, signature);
        vm.stopBroadcast();

        console.log("Mint with discount successful!");
        console.log("Balance after:", minter.balance);
        console.log("NFTs owned:", w3pass.balanceOf(minter));
    }
}