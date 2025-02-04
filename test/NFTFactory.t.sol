// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTFactory.sol";
import "../src/NFTCollection.sol";

contract NFTFactoryTest is Test {
    NFTFactory factory;
    address userOwner = address(0x12323);
    address user = address(0x123);
    address user2 = address(0x124);

    address owner = address(this);

    uint256 defaultMaxTime = block.timestamp + 120;

    receive() external payable {} 

    function setUp() public {
        vm.prank(userOwner);
        factory = new NFTFactory();
    }

    function testCreateCollection() public {
        vm.startPrank(owner);
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 1000, defaultMaxTime, false, 0);
        
        // Verify collection creation
        assertTrue(collectionAddress != address(0));
        assertEq(factory.getCollections().length, 1);
        
        // Verify collection properties
        NFTCollection collection = NFTCollection(collectionAddress);
        assertEq(collection.name(), "Test");
        assertEq(collection.symbol(), "TST");
        assertEq(collection.maxSupply(), 1000);
        assertEq(collection.owner(), owner);
    }

    function testMintNFTs() public {
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0);
        NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.deal(user, 1 ether);
        // Mint as user
        vm.prank(user);
        // Mint 5 NFTs
        collection.mintNFT{value: 0.0006 ether}(user, 5);
        assertEq(collection.totalSupply(), 5);
        assertEq(collection.ownerOf(1), user);
        assertEq(collection.ownerOf(5), user);
        
        // Test max supply limit
        vm.expectRevert("Exceeds max supply");
        collection.mintNFT{value: 0.0006 ether}(user, 6);
    }

    function testMetadata() public {
    address collectionAddress = factory.createCollection("Test", "TST", "Test Description", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0);
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // 3. Mint NFT
    collection.mintNFT{value: 0.0001 ether}(user, 1);
    
    // 4. Verify URI
    assertEq(collection.tokenURI(1), "data:application/json;base64,eyJuYW1lIjogIlRlc3QgIzEiLCJkZXNjcmlwdGlvbiI6IlRTVCIsImltYWdlIjogImlwZnM6Ly9RbVRlc3RIYXNoLyIsImF0dHJpYnV0ZXMiOiBbeyAidHJhaXRfdHlwZSI6ICJSYXJpdHkiLCAidmFsdWUiOiAiTGVnZW5kYXJ5IiB9XX0=");
}

    function testMaxTimeRestriction() public {
        // Create a collection with maxTime = 1 minute
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the allowed time
        collection.mintNFT{value: 0.0001 ether}(user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (1 second)
        vm.warp(block.timestamp + 1 hours + 1 seconds); // 61 seconds later
        vm.deal(user, 1 ether);
        // Attempt to mint after maxTime has passed
        vm.expectRevert("Minting period has ended");
        collection.mintNFT{value: 0.0001 ether}(user, 1);
    }

    function testDefaultMaxTime() public {
        // Create a collection with maxTime = 0 (defaults to 7 days)
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the default 7-day period
        collection.mintNFT{value: 0.0001 ether}(user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (7 days + 1 second)
        vm.warp(block.timestamp + 7 days + 1);
        vm.deal(user, 1 ether);
        // Attempt to mint after 7 days
        vm.expectRevert("Minting period has ended");
        collection.mintNFT{value: 0.0001 ether}(user, 1);
    }


    
    // Test should FAIL if minting works after maxTime (showing contract vulnerability)
    function testMaxTimeRestrictionFailure() public {
        // Create a collection with maxTime = 1 hour
        address collectionAddress = factory.createCollection("Test", "Test Description", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Simulate time passing (2 hours later)
        vm.warp(block.timestamp + 2 hours); // 2 hours later
        vm.deal(user, 1 ether);
        // Attempt to mint after maxTime has passed
        // This should REVERT if the contract is working correctly
        // If it does NOT revert, the test will pass (indicating a vulnerability)
        vm.expectRevert("Minting period has ended");
        collection.mintNFT{value: 0.0001 ether}(user, 1);
    }

    function testPaidMintAnotherUser() public {
    // Define addresses
    address nftOwner = address(0x122342343); // Explicit owner address
    address user22 = address(0x999999);

    // Set up owner balance tracking
    vm.deal(nftOwner, 0); // Ensure owner starts with 0 ETH
    uint256 ownerBalanceBefore = nftOwner.balance;

    // Create collection as owner
    vm.prank(nftOwner);
    uint nftPrice = 0.01 ether;
    uint platformFee = 0.0005 ether;
    address collectionAddress = factory.createCollection(
        "Paid", "Test Description", "PAID", "ipfs://paid/", 
        10,       // maxSupply
        defaultMaxTime,        // maxTime (1 hour)
        false,    // mintPerWallet
        nftPrice // mintPrice
    );
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // Fund user2 with ETH (1 ETH)
    vm.deal(user22, 1 ether);
    
    // Execute mint from user2
    vm.prank(user22);
    collection.mintNFT{value: nftPrice + platformFee}(user22, 1);
    
    // Verify balances
    assertEq(collection.totalSupply(), 1, "Mint failed");
    assertEq(user22.balance, 0.9895 ether, "User ETH not deducted"); // 1 ETH - 0.01 ETH
    assertEq(nftOwner.balance, ownerBalanceBefore + nftPrice, "Owner didn't receive ETH");
}

    function testMintWithoutPayment() public {
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.01 ether
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        vm.deal(user, 1 ether);
        vm.expectRevert("Insufficient ETH sent");
        collection.mintNFT{value: 0.0001 ether}(user, 1); // No ETH sent
    }

    function testInsufficientPayment() public {
        // Create a paid collection
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.01 ether // mintPrice = 0.01 ETH
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        vm.deal(user, 1 ether);
        // Attempt to mint with insufficient payment
        vm.prank(user);
        vm.expectRevert("Insufficient ETH sent");
        collection.mintNFT{value: 0.0001 ether}(user, 1); // Send 0.005 ETH
    }

    function testWalletRestriction() public {
        // Create a collection with wallet restriction
        address collectionAddress = factory.createCollection(
            "Restricted", "Test Description", "RST", "ipfs://restricted/", 
            10, defaultMaxTime, true, 0 // mintPerWallet = true
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.deal(user, 1 ether);
        // Mint as user
        vm.prank(user);
        collection.mintNFT{value: 0.0001 ether}(user, 1); // Mint 1 NFT
        
        // Attempt to mint again
        vm.prank(user);
        vm.expectRevert("Wallet already minted");
        collection.mintNFT{value: 0.0001 ether}(user, 1); // Should fail
    }









function testCreateAndMintFunction() public {
    address user = address(0x123); // Define an EOA
    vm.deal(user, 1 ether); // Fund the user

    vm.startPrank(user); // 👈 Execute as user, not test contract
    
    // Calculate required payment (mintPrice + platform fee)
    uint256 initialPrice = 0.0001 ether;
    uint256 totalPrice = initialPrice + 0.0001 ether; // Platform fee for <=0.002 ETH

    factory.createAndMint{value: totalPrice}(
        "TestCollection",
        "Test Description",
        "TST",
        "ipfs://test.png",
        true,
        initialPrice
    );
    
    // Verify collection creation
    address[] memory collections = factory.getCollections();
    assertEq(collections.length, 0, "Collection not created");
}

function testCalculatePlatformFee() public {
    // Create collection with different price scenarios
    address lowPriceCollection = factory.createCollection(
        "Low", "Desc", "LOW", "ipfs://low", 
        100, defaultMaxTime, false, 0.001 ether
    );
    address highPriceCollection = factory.createCollection(
        "High", "Desc", "HIGH", "ipfs://high", 
        100, defaultMaxTime, false, 0.003 ether
    );
    
    NFTCollection low = NFTCollection(lowPriceCollection);
    NFTCollection high = NFTCollection(highPriceCollection);
    
    // Should return 0.0001 ether for <= 0.002 ether
    assertEq(low.mintPrice(), 0.001 ether + 0.0001 ether, "Low price fee miscalculation");
    
    // Should return 5% of 0.003 ether = 0.00015 ether
    assertEq(high.mintPrice(), 0.003 ether + (0.003 ether * 5 / 100), "High price fee miscalculation");
}


function testAdminWithdraw() public {
    // Setup
    address admin = factory.owner();
    address nftOwner = address(0x1343);
    vm.deal(admin, 1 ether);

    // Create collection
    vm.prank(nftOwner);

    uint nftPrice = 0.003 ether;
    uint platformFee = 0.00015 ether;

    address collectionAddress = factory.createCollection(
        "High", "Desc", "HIGH", "ipfs://high", 
        100, defaultMaxTime, false, nftPrice
    );
    NFTCollection collection = NFTCollection(collectionAddress);

    // Mint NFTs (accumulate fees)
    vm.deal(user, 1 ether);
    vm.prank(user);
    collection.mintNFT{value: nftPrice + platformFee}(user, 1);

    // Verify withdrawal
    uint256 contractBalanceBefore = address(collection).balance;
    vm.prank(admin);
    collection.withdraw();
    
    assertEq(address(collection).balance, 0);
    assertEq(admin.balance, 1 ether + contractBalanceBefore);
}





// function testAdminFunctionsAccessControl() public {
    
//     address collectionAddress = factory.createCollection(
//         "AdminTest", "Desc", "ADM", "ipfs://admin", 
//         100, defaultMaxTime, false, 0.001 ether
//     );
//     NFTCollection collection = NFTCollection(collectionAddress);
    
//     // Test admin-only functions with non-admin
//     vm.startPrank(user);
    
//     vm.expectRevert("Only admin");
//     collection.setMaxSupply(200);
    
//     vm.expectRevert("Only admin");
//     collection.setMaxTime(200);
    
//     vm.expectRevert("Only admin");
//     collection.changePlatformFee(0.0002 ether);
    
//     // Test with admin (factory owner)
//     vm.stopPrank();
//     vm.startPrank(factory.owner());
    
//     collection.setMaxSupply(200);
//     assertEq(collection.maxSupply(), 200, "Max supply not updated");
    
//     collection.setMaxTime(200);
//     assertEq(collection.maxTime(), 200, "Max time not updated");
    
//     collection.changePlatformFee(0.0002 ether);
//     // Verify fee change through mint price calculation
//     collection.mintNFT{value: 0.0012 ether}(owner, 1);
// }

// function testIsDisabledConditions() public {
//     // Create restricted collection
//     address collectionAddress = factory.createCollection(
//         "DisabledTest", "Desc", "DIS", "ipfs://disabled", 
//         1, // maxSupply = 1
//         block.timestamp + 60, // 1 minute duration
//         true, // mintPerWallet
//         0.001 ether
//     );
//     NFTCollection collection = NFTCollection(collectionAddress);
    
//     // Initial state should be enabled
//     assertFalse(collection.isDisabled(owner), "Should not be disabled initially");
    
//     // Test supply limit
//     collection.mintNFT{value: 0.0011 ether}(owner, 1);
//     assertTrue(collection.isDisabled(owner), "Should disable after max supply");
    
//     // Create time-based test collection
//     address timeCollectionAddress = factory.createCollection(
//         "TimeTest", "Desc", "TIME", "ipfs://time", 
//         10, 
//         block.timestamp + 60, 
//         false, 
//         0.001 ether
//     );
//     NFTCollection timeCollection = NFTCollection(timeCollectionAddress);
    
//     // Advance past maxTime
//     vm.warp(block.timestamp + 61);
//     assertTrue(timeCollection.isDisabled(owner), "Should disable after maxTime");
    
//     // // Test wallet restriction
//     // address restrictedCollectionAddress = factory.createCollection(
//     //     "WalletTest", "Desc", "WALL", "ipfs://wallet", 
//     //     10, 
//     //     block.timestamp + 1000, 
//     //     true, // mintPerWallet
//     //     0.001 ether
//     // );
//     // NFTCollection restrictedCollection = NFTCollection(restrictedCollectionAddress);
    
//     // restrictedCollection.mintNFT{value: 0.0011 ether}(user, 1);
//     // assertTrue(restrictedCollection.isDisabled(user), "Should disable after wallet mint");
//     // assertFalse(restrictedCollection.isDisabled(user2), "Should allow other wallets");
// }

// function testCreateAndMintWithDefaults() public {

//         vm.deal(user, 1 ether);
//         vm.prank(user);
        
//         factory.createAndMint{value: 0.0002 ether}(
//             "DefaultTest",
//             "Test Description",
//             "DEF",
//             "ipfs://default.png",
//             true,
//             0 ether
//         );
        
//         address[] memory collections = factory.getCollections();
//         NFTCollection collection = NFTCollection(collections[0]);
        
//         // Verify default parameters
//         assertEq(collection.maxSupply(), type(uint256).max, "Default maxSupply not set");
//         assertEq(collection.maxTime(), block.timestamp + 60 + 168, "Default maxTime not set"); // Original test uses block.timestamp + 60 in constructor
//         assertTrue(collection.mintPerWallet(), "MintPerWallet not set");
//     }
}