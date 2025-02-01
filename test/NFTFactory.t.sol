// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTFactory.sol";
import "../src/NFTCollection.sol";

contract NFTFactoryTest is Test {
    NFTFactory factory;
    address user = address(0x123);
    address owner = address(this);

    function setUp() public {
        factory = new NFTFactory();
    }

    function testCreateCollection() public {
        vm.startPrank(owner);
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 1000, 1, false);
        
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
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 2, true);
        NFTCollection collection = NFTCollection(collectionAddress);
        
        // Mint 5 NFTs
        collection.mint(user, 5);
        assertEq(collection.totalSupply(), 5);
        assertEq(collection.ownerOf(1), user);
        assertEq(collection.ownerOf(5), user);
        
        // Test max supply limit
        vm.expectRevert("Exceeds max supply");
        collection.mint(user, 6);
    }

    function testMetadata() public {
    address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false);
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // 1. Set base URI
    // collection.setBaseURI("ipfs://QmTestHash/");
    
    // 2. Reveal the collection
    // collection.reveal(); // Add this line
    
    // 3. Mint NFT
    collection.mint(user, 1);
    
    // 4. Verify URI
    assertEq(collection.tokenURI(1), "ipfs://QmTestHash/");
}

    function testNonOwnerMint() public {
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false);
        NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        collection.mint(user, 1);
    }

    function testMaxTimeRestriction() public {
        // Create a collection with maxTime = 1 minute
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the allowed time
        collection.mint(user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (1 minute + 1 second)
        vm.warp(block.timestamp + 5 minutes); // 61 seconds later

        // Attempt to mint after maxTime has passed
        vm.expectRevert("Minting period has ended");
        collection.mint(user, 1);
    }

    function testDefaultMaxTime() public {
        // Create a collection with maxTime = 0 (defaults to 7 days)
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 0, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the default 7-day period
        collection.mint(user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (7 days + 1 second)
        vm.warp(block.timestamp +  1 minutes + 1 seconds);

        // Attempt to mint after 7 days
        vm.expectRevert("Minting period has ended");
        collection.mint(user, 1);
    }


    
    // Test should FAIL if minting works after maxTime (showing contract vulnerability)
    function testMaxTimeRestrictionFailure() public {
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        vm.warp(block.timestamp + 61); // 61 seconds later
        
        // Remove expectation to test for failure
        collection.mint(user, 1); // This should REVERT (test fails)
        
        // If execution reaches here, test passes (bad)
        assertEq(collection.totalSupply(), 1); 
    }
}