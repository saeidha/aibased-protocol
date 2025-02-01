// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTFactory.sol";
import "../src/NFTCollection.sol";

contract NFTFactoryTest is Test {
    NFTFactory factory;
    address user = address(0x123);
    address user2 = address(0x124);

    address owner = address(this);

    receive() external payable {} 

    function setUp() public {
        factory = new NFTFactory();
    }

    function testCreateCollection() public {
        vm.startPrank(owner);
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 1000, 1, false, 0);
        
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
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 2, false, 0);
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
    address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false, 0);
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
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false, 0);
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
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false, 0);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the allowed time
        collection.mint(user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (1 second)
        vm.warp(block.timestamp + 1 hours + 1 seconds); // 61 seconds later

        // Attempt to mint after maxTime has passed
        vm.expectRevert("Minting period has ended");
        collection.mintNotOwner(user, 1);
    }

    function testDefaultMaxTime() public {
        // Create a collection with maxTime = 0 (defaults to 7 days)
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 0, false, 0);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the default 7-day period
        collection.mintNotOwner{value: 0.00 ether}(user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (7 days + 1 second)
        vm.warp(block.timestamp + 7 days + 1);

        // Attempt to mint after 7 days
        vm.expectRevert("Minting period has ended");
        collection.mintNotOwner(user, 1);
    }


    
    // Test should FAIL if minting works after maxTime (showing contract vulnerability)
    function testMaxTimeRestrictionFailure() public {
        // Create a collection with maxTime = 1 hour
        address collectionAddress = factory.createCollection("Test", "TST", "ipfs://QmTestHash/", 10, 1, false, 0);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Simulate time passing (2 hours later)
        vm.warp(block.timestamp + 2 hours); // 2 hours later

        // Attempt to mint after maxTime has passed
        // This should REVERT if the contract is working correctly
        // If it does NOT revert, the test will pass (indicating a vulnerability)
        vm.expectRevert("Minting period has ended");
        collection.mintNotOwner(user, 1);
    }

    function testPaidMintAnotherUser() public {
    // Define addresses
    address owner1 = address(0x123); // Explicit owner address
    address user22 = address(0x124);

    // Set up owner balance tracking
    vm.deal(owner1, 0); // Ensure owner starts with 0 ETH
    uint256 ownerBalanceBefore = owner1.balance;

    // Create collection as owner
    vm.prank(owner1);
    address collectionAddress = factory.createCollection(
        "Paid", "PAID", "ipfs://paid/", 
        10,       // maxSupply
        1,        // maxTime (1 hour)
        false,    // mintPerWallet
        0.01 ether // mintPrice
    );
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // Fund user2 with ETH (1 ETH)
    vm.deal(user22, 1 ether);
    
    // Execute mint from user2
    vm.prank(user22);
    collection.mintNotOwner{value: 0.01 ether}(user22, 1);
    
    // Verify balances
    assertEq(collection.totalSupply(), 1, "Mint failed");
    assertEq(user22.balance, 0.99 ether, "User ETH not deducted"); // 1 ETH - 0.01 ETH
    assertEq(owner1.balance, ownerBalanceBefore + 0.01 ether, "Owner didn't receive ETH");
}

    function testMintWithoutPayment() public {
        address collectionAddress = factory.createCollection(
            "Paid", "PAID", "ipfs://paid/", 
            10, 1, false, 0.01 ether
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.expectRevert("Insufficient ETH sent");
        collection.mintNotOwner(user, 1); // No ETH sent
    }

    function testInsufficientPayment() public {
        // Create a paid collection
        address collectionAddress = factory.createCollection(
            "Paid", "PAID", "ipfs://paid/", 
            10, 1, false, 0.01 ether // mintPrice = 0.01 ETH
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        // Attempt to mint with insufficient payment
        vm.prank(user);
        vm.expectRevert("Insufficient ETH sent");
        collection.mintNotOwner{value: 0 ether}(user, 1); // Send 0.005 ETH
    }

    function testWalletRestriction() public {
        // Create a collection with wallet restriction
        address collectionAddress = factory.createCollection(
            "Restricted", "RST", "ipfs://restricted/", 
            10, 1, true, 0 // mintPerWallet = true
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        // Mint as user
        vm.prank(user);
        collection.mintNotOwner(user, 1); // Mint 1 NFT
        
        // Attempt to mint again
        vm.prank(user);
        vm.expectRevert("Wallet already minted");
        collection.mintNotOwner(user, 1); // Should fail
    }


}