// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/NFTFactory.sol";
import "../src/NFTCollection.sol";

contract NFTFactoryTest is Test {
    NFTFactory factory;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        factory = new NFTFactory();
    }

    // ERC721 receiver support for test contract
    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Test user mints tracking with uniqueness
    function testUserMintsTracking() public {
        vm.startPrank(user1);
        
        // Create collection via factory
        address collection = factory.createCollection(
            "Test", "Desc", "TST", "ipfs://test",
            100, 
            block.timestamp + 1 days,
            false, 
            0.001 ether, 
            false, 
            false
        );

        // Mint twice from same collection
        factory.mintNFT{value: 0.001 ether}(collection, user1, 1);
        factory.mintNFT{value: 0.001 ether}(collection, user1, 1);

        // Verify mint tracking (should have 1 unique entry)
        address[] memory mints = factory.getUserMints(user1);
        uint256 mintCount = factory.getUserMintCount(user1);
        
        assertEq(mintCount, 1, "Mint count mismatch");
        assertEq(mints[0], collection, "Mint record mismatch");
    }

    // Test collection creation tracking
    function testUserCollectionsTracking() public {
        vm.startPrank(user1);
        
        // Create two collections
        address coll1 = factory.createCollection(
            "Coll1", "Desc", "C1", "ipfs://1",
            100, block.timestamp + 1 days,
            false, 0.001 ether, false, false
        );
        
        address coll2 = factory.createCollection(
            "Coll2", "Desc", "C2", "ipfs://2",
            100, block.timestamp + 1 days,
            false, 0.001 ether, false, false
        );

        // Verify collections tracking
        address[] memory userCollections = factory.getUserCollections(user1);
        uint256 collectionCount = factory.getUserCollectionsCount(user1);

        assertEq(collectionCount, 2, "Collection count mismatch");
        assertEq(userCollections[0], coll1, "First collection mismatch");
        assertEq(userCollections[1], coll2, "Second collection mismatch");
    }

    // Test createAndMint vs createCollection behavior
    function testCollectionTypeTracking() public {
        vm.startPrank(user1);
        
        // Create via normal method
        address normalCollection = factory.createCollection(
            "Normal", "Desc", "N", "ipfs://normal",
            100, block.timestamp + 1 days,
            false, 0.001 ether, false, false
        );

        // Create via createAndMint
        factory.createAndMint{value: 0.1 ether}(
            "QuickMint", "Desc", "QM", "ipfs://quickmint"
        );
        // address quickCollection = factory.getCollections()[1];

        // Verify global tracking
        address[] memory allCollections = factory.getCollections();
        address[] memory mintPadCollections = factory.getMintPadCollections();

        // Both should appear in deployed collections
        assertEq(allCollections.length, 2, "Should have 2 total collections");
        
        // Only normal collection should be in mintPad
        assertEq(mintPadCollections.length, 1, "MintPad should have 1 collection");
        assertEq(mintPadCollections[0], normalCollection, "Wrong mintPad collection");
    }

    // Test cross-user isolation
    function testUserDataIsolation() public {
        // User1 creates collection
        vm.prank(user1);
        address user1Coll = factory.createCollection(
            "User1Coll", "Desc", "U1", "ipfs://u1",
            100, block.timestamp + 1 days,
            false, 0.001 ether, false, false
        );

        // User2 creates collection
        vm.prank(user2);
        address user2Coll = factory.createCollection(
            "User2Coll", "Desc", "U2", "ipfs://u2",
            100, block.timestamp + 1 days,
            false, 0.001 ether, false, false
        );

        // Verify isolation
        assertEq(factory.getUserCollections(user1)[0], user1Coll, "User1 collection mismatch");
        assertEq(factory.getUserCollections(user2)[0], user2Coll, "User2 collection mismatch");
        assertEq(factory.getUserCollectionsCount(user1), 1, "User1 should have 1 collection");
        assertEq(factory.getUserCollectionsCount(user2), 1, "User2 should have 1 collection");
    }

    // 1. Test initial empty state
    function testInitialEmptyState() view public {
        assertEq(factory.getUserMintCount(user1), 0, "Initial mint count should be 0");
        assertEq(factory.getUserCollectionsCount(user1), 0, "Initial collection count should be 0");
        assertEq(factory.getCollections().length, 0, "Initial collections should be empty");
        assertEq(factory.getMintPadCollections().length, 0, "Initial mintpad should be empty");
    }

    // 2. Test minting from multiple collections
    function testMultiCollectionMintTracking() public {
        vm.startPrank(user1);
        
        address coll1 = factory.createCollection("Coll1", "Desc", "C1", "ipfs://1",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);
        
        address coll2 = factory.createCollection("Coll2", "Desc", "C2", "ipfs://2",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);

        factory.mintNFT{value: 0.002 ether}(coll1, user1, 1);
        factory.mintNFT{value: 0.002 ether}(coll2, user1, 1);

        address[] memory mints = factory.getUserMints(user1);
        assertEq(mints.length, 2, "Should track 2 minted collections");
        assertEq(mints[0], coll1, "First mint mismatch");
        assertEq(mints[1], coll2, "Second mint mismatch");
    }

    // 3. Test cross-user mint tracking
    function testCrossUserMintTracking() public {
        // User1 creates collection
        vm.prank(user1);
        address coll = factory.createCollection("Coll", "Desc", "C", "ipfs://",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);

        // User2 mints from it
        vm.prank(user2);
        factory.mintNFT{value: 0.0011 ether}(coll, user2, 1);

        // Verify tracking
        assertEq(factory.getUserMintCount(user1), 0, "Creator shouldn't get mint tracking");
        assertEq(factory.getUserMintCount(user2), 1, "Minter should get tracking");
        assertEq(factory.getUserMints(user2)[0], coll, "Minter's mint record mismatch");
    }

    // 4. Test collection type differentiation
    function testCollectionTypeDifferentiation() public {
        vm.startPrank(user1);
        
        // Create via regular method
        address regularColl = factory.createCollection("Regular", "Desc", "RC", "ipfs://regular",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);
        
        // Create via createAndMint
        factory.createAndMint{value: 0.1 ether}("Quick", "Desc", "QC", "ipfs://quick");

        // Verify global tracking
        address[] memory allCollections = factory.getCollections();
        address[] memory mintPadCollections = factory.getMintPadCollections();

        assertEq(allCollections.length, 2, "Should track both collections");
        assertEq(mintPadCollections.length, 1, "Should only track regular in mintpad");
        assertEq(mintPadCollections[0], regularColl, "Mintpad collection mismatch");
    }

    // 5. Test duplicate mint prevention
    function testDuplicateMintPrevention() public {
        vm.startPrank(user1);
        
        address coll = factory.createCollection("Coll", "Desc", "C", "ipfs://",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);

        // Mint 5 times from same collection
        for(uint i = 0; i < 5; i++) {
            factory.mintNFT{value: 0.001 ether}(coll, user1, 1);
        }

        assertEq(factory.getUserMintCount(user1), 1, "Should count as single mint record");
        assertEq(factory.getUserMints(user1)[0], coll, "Mint record mismatch");
    }

    // 6. Test collection creation order
    function testCollectionCreationOrder() public {
        vm.startPrank(user1);
        
        address coll1 = factory.createCollection("First", "Desc", "1ST", "ipfs://1",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);
        
        address coll2 = factory.createCollection("Second", "Desc", "2ND", "ipfs://2",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);

        address[] memory collections = factory.getUserCollections(user1);
        assertEq(collections[0], coll1, "First collection mismatch");
        assertEq(collections[1], coll2, "Second collection mismatch");
    }

    // 7. Test mixed creation methods
    function testMixedCreationMethods() public {
        vm.startPrank(user1);
        
        // Create via different methods
        factory.createCollection("Regular", "Desc", "REG", "ipfs://regular",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);
        
        factory.createWithDefaultCollectionWithDefaultTime(
            "DefaultTime", "Desc", "DEF", "ipfs://defaulttime",
            100, false, 0.001 ether, false
        );

        factory.createWithDefaultCollectionWithDefaultTime(
            "DefaultTime", "Desc", "DEF", "ipfs://defaulttime",
            100, false, 0.001 ether, false
        );

        factory.createAndMint{value: 0.001 ether}("Quick", "Desc", "QCK", "ipfs://quick");

        factory.createAndMint{value: 0.1 ether}("QuickMint", "Desc", "QM", "ipfs://quick");

        vm.stopPrank();
        

        // Verify user collections
        assertEq(factory.getUserCollectionsCount(user1), 3, "Should track all creations");
        assertEq(factory.getUserMintCount(user1), 2, "Just mint user");
        assertEq(factory.getMintPadCollections().length, 3, "Should exclude createAndMint");


        vm.startPrank(user2);
        
        // Create via different methods
        factory.createCollection("Regular", "Desc", "REG", "ipfs://regular",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);
        
        factory.createWithDefaultCollectionWithDefaultTime(
            "DefaultTime", "Desc", "DEF", "ipfs://defaulttime",
            100, false, 0.001 ether, false
        );

        factory.createWithDefaultCollectionWithDefaultTime(
            "DefaultTime", "Desc", "DEF", "ipfs://defaulttime",
            100, false, 0.001 ether, false
        );

        factory.createAndMint{value: 0.001 ether}("Quick", "Desc", "QCK", "ipfs://quick");

        factory.createAndMint{value: 0.1 ether}("QuickMint", "Desc", "QM", "ipfs://quick");

        vm.stopPrank();
        

        // Verify user collections
        assertEq(factory.getUserCollectionsCount(user2), 3, "Should track all creations");
        assertEq(factory.getUserMintCount(user2), 2, "Just mint user");
        assertEq(factory.getMintPadCollections().length,6, "Should exclude createAndMint");
    }

    // 8. Test max supply edge case
    function testMaxSupplyTracking() public {
        vm.startPrank(user1);
        
        address coll = factory.createCollection("MaxSupply", "Desc", "MAX", "ipfs://max",
            1, // Max supply = 1
            block.timestamp + 1 days,
            true, // mintPerWallet
            0.001 ether, false, false
        );

        // Mint the only available NFT
        factory.mintNFT{value: 0.001 ether}(coll, user1, 1);

        // Verify mint tracking despite max supply
        assertEq(factory.getUserMintCount(user1), 1, "Should track mint even at max supply");
    }

    // 9. Test collection visibility in mintpad
    function testMintPadVisibility() public {
        vm.startPrank(user1);
        
        factory.createCollection("Visible", "Desc", "VIS", "ipfs://visible",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);
        
        factory.createCollection("Hidden", "Desc", "HID", "ipfs://hidden",
            100, block.timestamp + 1 days, true, 0.001 ether, false, false);

        // Assume canNotToShow() checks some visibility condition
        // Verify mintpad filtering
        address[] memory mintPad = factory.getMintPadCollections();
        assertEq(mintPad.length, 2, "Should include all created collections");
    }

    // 10. Test user collection ownership
    function testUserCollectionOwnership() public {
        vm.prank(user1);
        address coll = factory.createCollection("Owned", "Desc", "OWN", "ipfs://",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);

        vm.prank(user2);
        factory.createCollection("Other", "Desc", "OTH", "ipfs://",
            100, block.timestamp + 1 days, false, 0.001 ether, false, false);

        address[] memory user1Collections = factory.getUserCollections(user1);
        address[] memory user2Collections = factory.getUserCollections(user2);

        assertEq(user1Collections.length, 1, "User1 should have 1 collection");
        assertEq(user2Collections.length, 1, "User2 should have 1 collection");
        assertEq(user1Collections[0], coll, "Ownership mismatch");
    }
}