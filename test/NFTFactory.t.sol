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
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 1000);
        
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
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10);
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
    address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10);
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // 1. Set base URI
    // collection.setBaseURI("ipfs://QmTestHash/");
    
    // 2. Reveal the collection
    // collection.reveal(); // Add this line
    
    // 3. Mint NFT
    collection.mint(user, 1);
    
    // 4. Verify URI
    assertEq(collection.tokenURI(1), "ipfs://QmTestHash/1.json");
}

    function testNonOwnerMint() public {
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10);
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
}