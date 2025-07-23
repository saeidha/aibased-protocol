// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AIBasedNFTFactory} from "../src/AIBasedNFTFactory.sol";
import {NFTCollection} from "../src/NFTCollection.sol";

contract TestFeeLogic is Script {
    // --- State Variables for the Script ---
    AIBasedNFTFactory factory;
    
    address owner;
    uint256 ownerPrivateKey;

    address authorizer;
    uint256 authorizerPrivateKey;
    
    address regularUser;
    uint256 userPrivateKey;

    // --- Setup Function (Runs once before the script) ---
    function setUp() public {
        // Load all addresses and keys from the .env file
        factory = AIBasedNFTFactory(vm.envAddress("FACTORY_ADDRESS_SEPOLIA"));
        
        owner = vm.envAddress("DEPLYER_ADDRESS_SEPOLIA");
        ownerPrivateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");

        authorizer = vm.envAddress("AUTHORIZER_ADDRESS_SEPOLIA");
        authorizerPrivateKey = vm.envUint("AUTHORIZER_PRIVATE_KEY_SEPOLIA");

        regularUser = vm.envAddress("ANOTHER_INVALID_MINTER_ADDRESS_SEPOLIA");
        userPrivateKey = vm.envUint("ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA");

        // Ensure all keys are loaded
        require(ownerPrivateKey != 0, "OWNER_PRIVATE_KEY_SEPOLIA not set");
        require(authorizerPrivateKey != 0, "AUTHORIZER_PRIVATE_KEY_SEPOLIA not set");
        require(userPrivateKey != 0, "ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA not set");
    }

    // --- Main Run Function ---
    function run() public {
        test_payGenerationFee();
        test_setGenerationFee();
        test_feeCalculation();
        test_setBasePlatformFee();
        test_mintAndVerifyPlatformFee(); // Added new test
    }

    // --- Test Case 1: Paying the generation fee for a model ---
    function test_payGenerationFee() public {
        console.log("\n--- Testing payGenerateFee for model 'v1' ---");

        uint256 feeToPay = factory.getGenerationFee("v1");
        console.log("Fee for 'v1' is:", feeToPay);
        
        require(feeToPay > 0, "Generation fee for 'v1' is 0, cannot test payment.");

        // Pay the fee from the regular user's account
        vm.startBroadcast(userPrivateKey);
        factory.payGenerateFee{value: feeToPay}("v1");
        vm.stopBroadcast();

        console.log("Successfully paid the generation fee for 'v1'.");
    }

    // --- Test Case 2: Setting the generation fee by owner and authorizer ---
    function test_setGenerationFee() public {
        console.log("\n--- Testing setGenerationModelFee for model 'v2' ---");

        // --- A. Owner sets the fee ---
        uint256 newFeeByOwner = 0.00001 ether;
        console.log("Owner is setting 'v2' fee to:", newFeeByOwner);
        
        vm.startBroadcast(ownerPrivateKey);
        factory.setGenerationModelFee("v2", newFeeByOwner);
        vm.stopBroadcast();

        uint256 updatedFee = factory.getGenerationFee("v2");
        require(updatedFee == newFeeByOwner, "Owner failed to set the fee.");
        console.log("Owner successfully set the fee for 'v2' to:", updatedFee);

        // --- B. Authorizer sets the fee ---
        uint256 newFeeByAuthorizer = 0.00001 ether;
        console.log("Authorizer is setting 'v2' fee to:", newFeeByAuthorizer);

        vm.startBroadcast(authorizerPrivateKey);
        factory.setGenerationModelFee("v1", newFeeByAuthorizer);
        factory.setGenerationModelFee("v2", newFeeByAuthorizer);
        vm.stopBroadcast();

        updatedFee = factory.getGenerationFee("v1");
        require(updatedFee == newFeeByAuthorizer, "Authorizer failed to set the fee.");
        console.log("Authorizer successfully set the fee for 'v2' to:", updatedFee);
    }

    // --- Test Case 3: Verifying the platform fee calculation logic ---
    function test_feeCalculation() public {
        console.log("\n--- Testing getPlatformFee calculation logic ---");

        // --- A. Test with a low mint price (should return base fee) ---
        uint256 lowMintPrice = 0.001 ether;
        uint256 calculatedFeeLow = factory.getPlatformFee(lowMintPrice);
        uint256 baseFee = factory.basePlatformFee();
        
        console.log("Calculated fee for low price (", lowMintPrice, "):", calculatedFeeLow);
        console.log("Current base platform fee:", baseFee);
        require(calculatedFeeLow == baseFee, "Fee for low price should equal base fee.");
        console.log("Fee calculation correct for low mint price.");

        // --- B. Test with a high mint price (should return 5%) ---
        uint256 highMintPrice = 0.0025 ether;
        uint256 calculatedFeeHigh = factory.getPlatformFee(highMintPrice);
        uint256 expectedFee = (highMintPrice * 5) / 100;

        console.log("Calculated fee for high price (", highMintPrice, "):", calculatedFeeHigh);
        console.log("Expected 5% fee:", expectedFee);
        require(calculatedFeeHigh == expectedFee, "Fee for high price should be 5%.");
        console.log("Fee calculation correct for high mint price.");
    }

    // --- Test Case 4: Setting the base platform fee ---
    function test_setBasePlatformFee() public {
        console.log("\n--- Testing setBasePlatformFee ---");

        uint256 newBaseFee = 0.0001 ether;
        console.log("Owner is setting base platform fee to:", newBaseFee);

        vm.startBroadcast(ownerPrivateKey);
        factory.setBasePlatformFee(newBaseFee);
        vm.stopBroadcast();

        uint256 updatedBaseFee = factory.basePlatformFee();
        require(updatedBaseFee == newBaseFee, "Failed to update base platform fee.");
        console.log("Base platform fee successfully updated to:", updatedBaseFee);
    }

    // --- NEW Test Case 5: Minting and verifying the platform fee is sent to the factory ---
    function test_mintAndVerifyPlatformFee() public {
        console.log("\n--- Testing mint and verifying platform fee transfer to OWNER ---");

        // Step 1: Create a collection with a low mint price to trigger the base fee
        uint256 mintPrice = 0.001 ether;
        vm.startBroadcast(userPrivateKey);
        address newCollectionAddress = factory.createCollection(
            "Fee Test Collection", "A collection to test fee transfers.", "v-fee", "s-fee", "FEE",
            "some-image-url", 100, block.timestamp + 1 days, false, mintPrice, false, false
        );
        vm.stopBroadcast();
        require(newCollectionAddress != address(0), "Failed to create collection for fee test.");
        console.log("Created collection for fee test at:", newCollectionAddress);

        // Step 2: Calculate the expected fee and get the factory owner's balance before the mint
        uint256 expectedFee = factory.getPlatformFee(mintPrice);
        uint256 totalValue = mintPrice + expectedFee;
        
        // Check the owner's balance, not the factory's.
        uint256 ownerBalanceBefore = owner.balance;

        console.log("Factory's OWNER balance before mint:", ownerBalanceBefore);
        console.log("Minting with total value (price + fee):", totalValue);

        // Step 3: Mint from the new collection
        vm.startBroadcast(userPrivateKey);
        factory.mintNFT{value: totalValue}(newCollectionAddress, regularUser, 1);
        vm.stopBroadcast();

        // Step 4: Verify the factory owner's balance increased by the exact fee amount
        uint256 ownerBalanceAfter = owner.balance;
        console.log("Factory's OWNER balance after mint:", ownerBalanceAfter);

        require(ownerBalanceAfter == ownerBalanceBefore + expectedFee, "Factory's OWNER did not receive the correct platform fee.");
        console.log("Factory's OWNER correctly received the platform fee of", expectedFee);
    }
}
