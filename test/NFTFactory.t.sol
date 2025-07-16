// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/AIBasedNFTFactory.sol";
import "../src/NFTCollection.sol";

contract NFTFactoryTest is Test {
    AIBasedNFTFactory factory;
    address user = address(0x123);
    address user2 = address(0x124);

    address owner = address(this);

    uint256 defaultMaxTime = block.timestamp + 120;
    uint256 defaultGenerateFee = 0.0001 ether;

    receive() external payable {} 

    function setUp() public {
        vm.prank(owner);
        factory = new AIBasedNFTFactory();
    }
///-------------------------------------------------------- HELPER FUNCTIONS ------------------------------------------------------------------///
    function getCollections() internal view returns (address[] memory) {
    // Call the explicit getter function you defined in the factory
    return factory.getCollections(); 
}

function getMintPadCollections() internal view returns (address[] memory) {
    // Call the explicit getter function you defined in the factory
    return factory.getMintPadCollections();
}

    function getAvailableCollectionsToMintDetails() internal view returns (AIBasedNFTFactory.CollectionDetails[] memory) {
        
        uint256 mintPadCollectionsLength = factory.getMintPadCollections().length;
        AIBasedNFTFactory.CollectionDetails[] memory details = new AIBasedNFTFactory.CollectionDetails[](mintPadCollectionsLength);
        uint256 count = 0;
        for (uint256 i = 0; i < mintPadCollectionsLength; i++) {
            NFTCollection collection = NFTCollection(factory.getMintPadCollections()[i]);
            if (!collection.canNotToShow()) {
                uint256 mintPrice = collection.mintPrice();
                details[count++] = _getCollectionDetails(collection, factory.getMintPadCollections()[i], true, mintPrice, mintPrice);
            }
        }
        return _trimDetails(details, count);
    }

    function getAvailableCollectionsToMintDetails(address sender) internal view returns (AIBasedNFTFactory.CollectionDetails[] memory) {
        uint256 mintPadCollectionsLength = factory.getMintPadCollections().length;
        AIBasedNFTFactory.CollectionDetails[] memory details = new AIBasedNFTFactory.CollectionDetails[](mintPadCollectionsLength);
        uint256 count = 0;
        for (uint256 i = 0; i < mintPadCollectionsLength; i++) {
            NFTCollection collection = NFTCollection(factory.getMintPadCollections()[i]);
            if (!collection.canNotToShow()) {
                AIBasedNFTFactory.CollectionDetails memory detail = _getCollectionDetails(collection, factory.getMintPadCollections()[i], false, collection.mintPrice(),  collection.mintPriceForUser(sender));
                detail.isDisable = collection.isDisabled(sender);
                details[count++] = detail;
            }
        }
        return _trimDetails(details, count);
    }

    function getUserCollectionsDetails(address sender) internal view returns (AIBasedNFTFactory.CollectionDetails[] memory) {
        uint256 mintPadCollectionsLength = factory.getMintPadCollections().length;
        address[] memory usersCollections = factory.getUserCollection(sender);
        AIBasedNFTFactory.CollectionDetails[] memory details = new AIBasedNFTFactory.CollectionDetails[](mintPadCollectionsLength);
        for (uint256 i = 0; i < mintPadCollectionsLength; i++) {
            NFTCollection collection = NFTCollection(usersCollections[i]);
            details[i] = _getCollectionDetails(collection, usersCollections[i], false, collection.mintPrice(),  collection.mintPriceForUser(sender));
            details[i].isDisable = collection.isDisabled(sender);
        }
        return details;
    }

    function getCollectionDetailsByContractAddress(address contractAddress) internal view returns (AIBasedNFTFactory.CollectionDetails memory) {
        uint256 deployedCollectionsLength = factory.getCollections().length;
        for (uint256 i = 0; i < deployedCollectionsLength; i++) {
            if (factory.getCollections()[i] == contractAddress) {
                NFTCollection collection = NFTCollection(factory.getCollections()[i]);
                uint256 mintPrice = collection.mintPrice();
                return _getCollectionDetails(collection, factory.getCollections()[i], true, mintPrice, mintPrice);
            }
        }
        return _emptyCollectionDetails();
    }

    function getCollectionDetailsByContractAddress(address contractAddress, address sender) internal view returns (AIBasedNFTFactory.CollectionDetails memory) {
        uint256 deployedCollectionsLength = factory.getCollections().length;
        for (uint256 i = 0; i < deployedCollectionsLength; i++) {
            if (factory.getCollections()[i] == contractAddress) {
                NFTCollection collection = NFTCollection(factory.getCollections()[i]);
                AIBasedNFTFactory.CollectionDetails memory detail = _getCollectionDetails(collection, factory.getCollections()[i], false, collection.mintPrice(),  collection.mintPriceForUser(sender));
                detail.isDisable = collection.isDisabled(sender);
                return detail;
            }
        }
        return _emptyCollectionDetails();
    }


    function getUserMints(address user) internal view returns (address[] memory) {
        return factory.getMintCollection(user);
    }

    function getUserMintCount(address user) internal view returns (uint256) {
        return factory.getMintCollection(user).length;
    }

    function getUserCollectionsCount(address user) internal view returns (uint256) {
        return factory.getUserCollection(user).length;
    }

    function getUserCollections(address user) internal view returns (address[] memory) {
        return factory.getUserCollection(user);
    }

    // Helper functions to reduce code duplication
    function _getCollectionDetails(NFTCollection collection, 
    address collectionAddress, bool isDisable, uint256 mintPrice, 
    uint256 actualPrice) private view returns (AIBasedNFTFactory.CollectionDetails memory) {
        return AIBasedNFTFactory.CollectionDetails({
            collectionAddress: collectionAddress,
            name: collection.name(),
            description: collection.description(),
            tokenIdCounter: collection.totalSupply(),
            maxSupply: collection.maxSupply(),
            baseImageURI: collection.imageURL(),
            maxTime: collection.maxTime(),
            mintPerWallet: collection.mintPerWallet(),
            mintPrice: mintPrice,
            actualPrice: actualPrice,
            isDisable: isDisable,
            isUltimateMintTime: collection.isUltimateMintTime(),
            isUltimateMintQuantity: collection.isUltimateMintQuantity()
        });
    }

    function _trimDetails(AIBasedNFTFactory.CollectionDetails[] memory details, uint256 count) private pure 
            returns (AIBasedNFTFactory.CollectionDetails[] memory) {
        AIBasedNFTFactory.CollectionDetails[] memory trimmed = new AIBasedNFTFactory.CollectionDetails[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmed[i] = details[i];
        }
        return trimmed;
    }

    function _emptyCollectionDetails() private pure returns (AIBasedNFTFactory.CollectionDetails memory) {
        return AIBasedNFTFactory.CollectionDetails({
            collectionAddress: address(0),
            name: "",
            description: "",
            tokenIdCounter: 0,
            maxSupply: 0,
            baseImageURI: "",
            maxTime: 0,
            mintPerWallet: false,
            mintPrice: 0,
            actualPrice: 0,
            isDisable: false,
            isUltimateMintTime: false,
            isUltimateMintQuantity: false
        });
    }


///-------------------------------------------------------- HELPER FUNCTIONS ------------------------------------------------------------------///

    function testCreateCollection() public {
        vm.startPrank(owner);
        address collectionAddress = factory.createCollection("Test", "Test Description", "v1", "cartone", "TST", "ipfs://QmTestHash/", 1000, defaultMaxTime, false, 0, false, false);
        
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
        address collectionAddress = factory.createCollection("Test", "Test Description", "v1", "cartone", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.deal(user, 1 ether);
        // Mint as user
        vm.prank(user);
        // Mint 5 NFTs
        factory.mintNFT{value: 0.0006 ether}(collectionAddress, user, 5);
        assertEq(collection.totalSupply(), 5);
        assertEq(collection.ownerOf(1), user);
        assertEq(collection.ownerOf(5), user);
        
        // Test max supply limit
        vm.expectRevert("Exceeds max supply");
        factory.mintNFT{value: 0.0006 ether}(collectionAddress, user, 6);
    }

    function testMetadata() public {
        address collectionAddress = factory.createCollection("Test", "TST", "v1", "cartone", "Test Description", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);
        
        // 3. Mint NFT
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
        
        // 4. Verify URI
        assertEq(collection.tokenURI(1), "data:application/json;base64,eyJuYW1lIjoiVGVzdCAjMSIsImRlc2NyaXB0aW9uIjoiVFNUIiwiaW1hZ2UiOiJpcGZzOi8vUW1UZXN0SGFzaC8ifQ==");
    }

    function testMaxTimeRestriction() public {
        // Create a collection with maxTime = 1 minute
        address collectionAddress = factory.createCollection("Test", "Test Description", "v1", "cartone", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the allowed time
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (1 second)
        vm.warp(block.timestamp + 1 hours + 1 seconds); // 61 seconds later
        vm.deal(user, 1 ether);
        // Attempt to mint after maxTime has passed
        vm.expectRevert("Minting period has ended");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
    }

    function testDefaultMaxTime() public {
        // Create a collection with maxTime = 0 (defaults to 7 days)
        address collectionAddress = factory.createCollection("Test", "Test Description", "v1", "cartone", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        NFTCollection collection = NFTCollection(collectionAddress);

        // Mint within the default 7-day period
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
        assertEq(collection.totalSupply(), 1);

        // Simulate time passing (7 days + 1 second)
        vm.warp(block.timestamp + 7 days + 1);
        vm.deal(user, 1 ether);
        // Attempt to mint after 7 days
        vm.expectRevert("Minting period has ended");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
    }


    
    // Test should FAIL if minting works after maxTime (showing contract vulnerability)
    function testMaxTimeRestrictionFailure() public {
        // Create a collection with maxTime = 1 hour
        address collectionAddress = factory.createCollection("Test", "Test Description", "v1", "cartone", "TST", "ipfs://QmTestHash/", 10, defaultMaxTime, false, 0, false, false);
        // NFTCollection collection = NFTCollection(collectionAddress);

        // Simulate time passing (2 hours later)
        vm.warp(block.timestamp + 2 hours); // 2 hours later
        vm.deal(user, 1 ether);
        // Attempt to mint after maxTime has passed
        // This should REVERT if the contract is working correctly
        // If it does NOT revert, the test will pass (indicating a vulnerability)
        vm.expectRevert("Minting period has ended");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1);
    }

    function testPaidMintAnotherUser() public {
    // Define addresses
    address user22 = address(0x999999);

    // Set up owner balance tracking
    vm.deal(owner, 0); // Ensure owner starts with 0 ETH
    uint256 ownerBalanceBefore = owner.balance;

    // Create collection as owner
    vm.prank(owner);
    uint nftPrice = 0.01 ether;
    uint platformFee = 0.0005 ether;
    address collectionAddress = factory.createCollection(
        "Paid", "Test Description", "v1", "cartone", "PAID", "ipfs://paid/", 
        10,       // maxSupply
        defaultMaxTime,        // maxTime (1 hour)
        false,    // mintPerWallet
        nftPrice // mintPrice
        , false, false
    );
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // Fund user2 with ETH (1 ETH)
    vm.deal(user22, 1 ether);
    
    // Execute mint from user2
    vm.prank(user22);
    factory.mintNFT{value: nftPrice + platformFee}(collectionAddress, user22, 1);
    
    // Verify balances
    assertEq(collection.totalSupply(), 1, "Mint failed");
    assertEq(user22.balance, 0.9895 ether, "User ETH not deducted"); // 1 ETH - 0.01 ETH
    assertEq(owner.balance, ownerBalanceBefore + nftPrice, "Owner didn't receive ETH");
}

    function testMintWithoutPayment() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "v1", "cartone", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.01 ether, false, false
        );
        // NFTCollection collection = NFTCollection(collectionAddress);
        vm.expectRevert("Insufficient ETH sent");
        factory.mintNFT{value: 0.000005 ether}(collectionAddress, user, 1); // No ETH sent
    }


    function testMintByCreatorPayment() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "v1", "cartone", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.2 ether, false, false
        );
        // NFTCollection collection = NFTCollection(collectionAddress);
        
        // vm.expectRevert("Insufficient ETH sent");
        // factory.mintNFT{value: 0.00005 ether}(user, 1); // No ETH sent

        factory.mintNFT{value: 0.01 ether}(collectionAddress, user, 1); // No ETH sent
    }

    function testInsufficientPayment() public {
        // Create a paid collection
        address collectionAddress = factory.createCollection(
            "Paid", "Test Description", "v1", "cartone", "PAID", "ipfs://paid/", 
            10, defaultMaxTime, false, 0.01 ether // mintPrice = 0.01 ETH
            , false, false
        );
        // NFTCollection collection = NFTCollection(collectionAddress);
        vm.deal(user, 1 ether);
        // Attempt to mint with insufficient payment
        vm.prank(user);
        vm.expectRevert("Insufficient ETH sent");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1); // Send 0.005 ETH
    }

    function testWalletRestriction() public {
        // Create a collection with wallet restriction
        address collectionAddress = factory.createCollection(
            "Restricted", "Test Description", "v1", "cartone", "RST", "ipfs://restricted/", 
            10, defaultMaxTime, true, 0 // mintPerWallet = true
            , false, false
        );
        // NFTCollection collection = NFTCollection(collectionAddress);
        
        vm.deal(user, 1 ether);
        // Mint as user
        vm.prank(user);
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1); // Mint 1 NFT
        
        // Attempt to mint again
        vm.prank(user);
        vm.expectRevert("Wallet already minted");
        factory.mintNFT{value: 0.0001 ether}(collectionAddress, user, 1); // Should fail
    }



function testCreateAndMintFunction() public {
    // address user = address(0x123); // Define an EOA
    vm.deal(user, 1 ether); // Fund the user

    vm.startPrank(user); // 👈 Execute as user, not test contract
    
    // Calculate required payment (mintPrice + platform fee)
    uint256 initialPrice = 0.0001 ether;
    uint256 totalPrice = initialPrice + 0.0001 ether; // Platform fee for <=0.002 ETH

    factory.createAndMint{value: totalPrice}(
        "TestCollection",
        "Test Description",
        "v1", "cartone",
        "TST",
        "ipfs://test.png"
    );
    
    // Verify collection creation
    address[] memory collections = factory.getCollections();
    address[] memory mintpadCollections = factory.getMintPadCollections();
    assertEq(collections.length, 1, "Collection not created");

    assertEq(mintpadCollections.length, 0, "Mintpad Collection not created");
}

function testCalculatePlatformFee() public {
    // Create collection with different price scenarios
    address lowPriceCollection = factory.createCollection(
        "Low", "Desc", "v1", "cartone", "LOW", "ipfs://low", 
        100, defaultMaxTime, false, 0.001 ether, false, false
    );
    address highPriceCollection = factory.createCollection(
        "High", "Desc", "v1", "cartone", "HIGH", "ipfs://high", 
        100, defaultMaxTime, false, 0.003 ether, false, false
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
    uint256 adminBalanceBefore = admin.balance;
    // Create collection
    vm.prank(owner);

    uint nftPrice = 0.003 ether;
    uint platformFee = 0.00015 ether;

    address collectionAddress = factory.createCollection(
        "High", "Desc", "v1", "cartone", "HIGH", "ipfs://high", 
        100, defaultMaxTime, false, nftPrice, false, false
    );
    NFTCollection collection = NFTCollection(collectionAddress);

    // Mint NFTs (accumulate fees)
    vm.deal(user, 1 ether);
    vm.prank(user);
    factory.mintNFT{value: nftPrice + platformFee}(collectionAddress, user, 1);
    assertEq(admin.balance - adminBalanceBefore, nftPrice);
    assertEq(address(collection).balance, platformFee);
    // assertEq(admin.balance, 1 ether + nftPrice);
    // Verify withdrawal
    uint256 contractBalanceBefore = address(collection).balance;
    vm.prank(admin);
    collection.withdraw();
    
    assertEq(address(collection).balance, 0);
    assertEq(admin.balance - adminBalanceBefore, contractBalanceBefore + nftPrice);
}


function testAdminFunctionsAccessControl() public {
    
    uint nftFee = 0.001 ether;
    vm.deal(user, 1 ether);
    vm.startPrank(user);
    address collectionAddress = factory.createCollection(
        "AdminTest", "Desc", "v1", "cartone", "ADM", "ipfs://admin", 
        100, defaultMaxTime, false, nftFee, false, false
    );
    NFTCollection collection = NFTCollection(collectionAddress);
    
    // Test admin-only functions with non-admin
    
    
    vm.expectRevert(abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector, 
        user
    ));
    collection.setMaxSupply(200);
    
    vm.expectRevert(abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector, 
        user
    ));
    collection.setMaxTime(200);
    
    vm.expectRevert(abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector, 
        user
    ));
    collection.changePlatformFee(0.0002 ether);
    
    // Test with admin (factory owner)
    vm.stopPrank();
    vm.startPrank(factory.owner());
    
    collection.setMaxSupply(200);
    assertEq(collection.maxSupply(), 200, "Max supply not updated");
    
    collection.setMaxTime(200);
    assertEq(collection.maxTime(), 200, "Max time not updated");
    
    uint changeFee = 0.0002 ether;
    collection.changePlatformFee(changeFee);

    vm.stopPrank();
    vm.startPrank(user);
    
    // Verify fee change through mint price calculation
    factory.mintNFT{value: nftFee + changeFee}(collectionAddress, user, 1);
}

    function testIsDisabledConditions() public {

        vm.deal(owner, 1 ether);
        // Create restricted collection
        address collectionAddress = factory.createCollection(
            "DisabledTest", "Desc", "v1", "cartone", "DIS", "ipfs://disabled", 
            1, // maxSupply = 1
            block.timestamp + 60, // 1 minute duration
            true, // mintPerWallet
            0.001 ether, false, false
        );
        NFTCollection collection = NFTCollection(collectionAddress);
        
        // Initial state should be enabled
        assertFalse(collection.isDisabled(user), "Should not be disabled initially");
        
        factory.mintNFT{value: 0.0012 ether}(collectionAddress, user, 1);
    
        assertTrue(collection.isDisabled(user), "Should disable after max supply");
        
        // Create time-based test collection
        address timeCollectionAddress = factory.createCollection(
            "TimeTest", "Desc", "v1", "cartone", "TIME", "ipfs://time", 
            10, 
            block.timestamp + 60, 
            false, 
            0.001 ether, false, false
        );
        NFTCollection timeCollection = NFTCollection(timeCollectionAddress);
        
        // Advance past maxTime
        vm.warp(block.timestamp + 61);
        assertTrue(timeCollection.isDisabled(user), "Should disable after maxTime");
        
        // Test wallet restriction
        address restrictedCollectionAddress = factory.createCollection(
            "WalletTest", "Desc", "v1", "cartone", "WALL", "ipfs://wallet", 
            10, 
            block.timestamp + 1000, 
            true, // mintPerWallet
            0.001 ether, false, false
        );
        NFTCollection restrictedCollection = NFTCollection(restrictedCollectionAddress);
        
        factory.mintNFT{value: 0.0011 ether}(restrictedCollectionAddress, user, 1);
        assertTrue(restrictedCollection.isDisabled(user), "Should disable after wallet mint");
        assertFalse(restrictedCollection.isDisabled(user2), "Should allow other wallets");
    }

    // Test payGenerateFee with sufficient ETH
    function testPayGenerateFeeSuccess() public {
        uint256 fee = defaultGenerateFee;
        vm.deal(user, fee);
        
        vm.prank(user);
        
        factory.payGenerateFee{value: fee}();

        assertEq(address(factory).balance, fee, "Contract should have received fee");
    }

    // Test payGenerateFee with insufficient ETH
    function testPayGenerateFeeInsufficient() public {
        vm.startPrank(owner);
        uint256 newFee = 0.0001 ether;
        factory.setGenerateFee(newFee);
        uint256 fee = defaultGenerateFee;
        
        
        vm.stopPrank();
        vm.deal(user, fee - 1);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(AIBasedNFTFactory.InsufficientFee.selector));
        factory.payGenerateFee{value: fee - 1}();
    }

    // Test owner withdrawal
    function testWithdrawAsOwner() public {
        
        uint256 fee = defaultGenerateFee;
        vm.startPrank(owner);
        factory.setGenerateFee(fee);
        vm.stopPrank();


        vm.deal(user, fee);
        
        // Fund contract
        vm.prank(user);
        factory.payGenerateFee{value: fee}();

        uint256 contractBalanceBefore = address(factory).balance;
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        factory.withdraw();

        assertEq(address(factory).balance, 0, "Contract balance should be 0");
        assertEq(
            owner.balance,
            ownerBalanceBefore + contractBalanceBefore,
            "Owner should receive contract balance"
        );
    }

    // Test non-owner withdrawal attempt
    function testWithdrawAsNonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector, 
        user
        ));
        factory.withdraw();
    }

    // Test fee update by owner
    function testSetGenerateFeeAsOwner() public {
        vm.startPrank(owner);
        uint256 newFee = 0.2 ether;
        factory.setGenerateFee(newFee);
        assertEq(factory.getFee(), newFee, "Fee should update");
    }

 // Test fee payment functionality
    function testPayGenerateFee() public {
        uint256 fee = 0.001 ether;
        
        // Set fee by owner
        vm.prank(owner);
        factory.setGenerateFee(fee);

        // Test successful payment
        vm.deal(user, fee);
        vm.prank(user);
        factory.payGenerateFee{value: fee}();
        assertEq(address(factory).balance, fee, "Fee not received");

        // Test insufficient payment
        vm.deal(user2, fee - 1);
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(AIBasedNFTFactory.InsufficientFee.selector));
        factory.payGenerateFee{value: fee - 1}();
    }

    // Test withdrawal functionality
    function testWithdraw() public {
        uint256 fee = 0.001 ether;
        
        // Setup
        vm.prank(owner);
        factory.setGenerateFee(fee);
        
        vm.deal(user, fee);
        vm.prank(user);
        factory.payGenerateFee{value: fee}();

        // Test owner withdrawal
        uint256 initialBalance = owner.balance;
        vm.prank(owner);
        factory.withdraw();
        
        assertEq(address(factory).balance, 0, "Funds not withdrawn");
        assertEq(owner.balance, initialBalance + fee, "Funds not received");

        // Test non-owner withdrawal attempt
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector, 
        user
        ));
        factory.withdraw();
    }

    // Test fee management
    function testFeeManagement() public {
        uint256 newFee = 0.002 ether;
        
        // Test owner sets fee
        vm.startPrank(owner);
        factory.setGenerateFee(newFee);
        assertEq(factory.getFee(), newFee, "Fee not updated");
        vm.stopPrank();
        // Test non-owner sets fee
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(
        Ownable.OwnableUnauthorizedAccount.selector, 
        user));
        factory.setGenerateFee(newFee);
    }

 // Test retrieving details for a valid contract address
    function testGetDetailsByValidAddress() public {
        // Create a test collection
        address collectionAddress = createTestCollection(owner, 100, block.timestamp + 1 days, false);
        
        // Retrieve details
        AIBasedNFTFactory.CollectionDetails memory details = getCollectionDetailsByContractAddress(collectionAddress);
        
        // Verify returned details
        assertEq(details.collectionAddress, collectionAddress, "Incorrect collection address");
        assertEq(details.maxSupply, 100, "Incorrect max supply");
        assertEq(details.mintPerWallet, false, "Incorrect mint restriction");
        assertEq(details.isDisable, true, "Incorrect disable status");
    }

    // // Test retrieving details for an invalid contract address
    // function testGetDetailsByInvalidAddress() view public {
    //     // Attempt to retrieve details for a non-existent collection
    //     address invalidAddress = address(0x999);
        
    //     // Expect the function to revert or return empty details
    //    AIBasedNFTFactory.CollectionDetails memory invalidResult = getCollectionDetailsByContractAddress(invalidAddress);
    //     assertTrue(address(0) == invalidResult.collectionAddress, "Incorrect collection address");
    // }

    // Test retrieving details for a collection with ultimate mint conditions
    function testGetDetailsWithUltimateMintConditions() public {
        // Create a time-sensitive collection (last hour)
        address timeCol = createTestCollection(owner, 1000, type(uint256).max, false);
        
        // Create a quantity-sensitive collection
        address quantityCol = createTestCollection(owner, type(uint256).max, block.timestamp + 1 days, false);

        // Retrieve details for time-sensitive collection
        AIBasedNFTFactory.CollectionDetails memory timeDetails = getCollectionDetailsByContractAddress(timeCol);
        assertTrue(timeDetails.isUltimateMintTime, "Should indicate ultimate mint time");

        // // Retrieve details for quantity-sensitive collection
        AIBasedNFTFactory.CollectionDetails memory quantityDetails = getCollectionDetailsByContractAddress(quantityCol);
        assertTrue(quantityDetails.isUltimateMintQuantity, "Should indicate ultimate mint quantity");
    }

    // Test retrieving details for a collection with minting restrictions
    function testGetDetailsWithMintRestrictions() public {
        // Create a restricted collection
        address restrictedCol = createTestCollection(owner, 10, block.timestamp + 1 days, true);
        
        // Mint from restricted collection to trigger wallet restriction
        vm.deal(user, 0.1 ether);
        vm.prank(user);
        factory.mintNFT{value: 0.0002 ether}(restrictedCol, user, 1);

        // Retrieve details
        AIBasedNFTFactory.CollectionDetails memory details = getCollectionDetailsByContractAddress(restrictedCol);
        
        // Verify restrictions
        assertTrue(details.mintPerWallet, "Should indicate mint per wallet restriction");
        assertTrue(details.isDisable, "Should indicate disabled status for restricted collection");
    }

    // Helper to create test collections
    function createTestCollection(address creator, uint256 maxSupply, uint256 maxTime, bool mintPerWallet) internal returns (address) {
        vm.startPrank(creator);
        address collectionAddress = factory.createCollection(
            "Test",
            "Test Description",  "v1", "cartone",
            "TST",
            "ipfs://test",
            maxSupply,
            maxTime,
            mintPerWallet,
            0.0001 ether,
            false,
            false
        );
        vm.stopPrank();

        return collectionAddress;
    }

    // Helper to mint multiple NFTs
    function mintMultiple(address collection, address minter, uint256 quantity) internal {
        
        vm.prank(minter);
        for (uint256 i = 0; i < quantity; i++) {
            factory.mintNFT{value: 0.0001 ether}(collection, minter, 1);
        }
    }


    function testCreateCollectionCGETSollection() public {
        string memory name = "Test Collection";
        string memory description = "A test NFT collection";
        string memory symbol = "TEST";
        string memory imageURL = "https://example.com/image.png";
        uint256 maxSupply = 100;
        uint256 maxTime = block.timestamp + 10 days;
        bool mintPerWallet = true;
        uint256 mintPrice = 0.01 ether;
        bool isUltimateMintTime = false;
        bool isUltimateMintQuantity = false;
        uint256 mintPriceWithFee = 0.0105 ether;
        // Create a new collection
        address collectionAddress = factory.createCollection(
            name,
            description, "v1", "cartone",
            symbol,
            imageURL,
            maxSupply,
            maxTime,
            mintPerWallet,
            mintPrice,
            isUltimateMintTime,
            isUltimateMintQuantity
        );

        // Verify the collection was deployed
        NFTCollection collection = NFTCollection(collectionAddress);
        assertEq(collection.name(), name);
        assertEq(collection.symbol(), symbol);
        assertEq(collection.imageURL(), imageURL);
        assertEq(collection.maxSupply(), maxSupply);
        assertEq(collection.maxTime(), maxTime);
        assertEq(collection.mintPerWallet(), mintPerWallet);
        assertEq(collection.mintPrice(), mintPriceWithFee);

        // Verify the collection is added to deployedCollections
        address[] memory collections = factory.getCollections();

        assertEq(collections.length, 1);
        assertEq(collections[0], collectionAddress);

        AIBasedNFTFactory.CollectionDetails[] memory avaiableColloctions = getAvailableCollectionsToMintDetails();
        assertEq(avaiableColloctions.length, 1);
        assertEq(avaiableColloctions[0].collectionAddress, collectionAddress);
    }

    function testCreateWithDefaultCollectionWithDefaultTime() public {
        string memory name = "Default Time Collection";
        string memory description = "A test collection with default time";
        string memory symbol = "DFLT";
        string memory imageURL = "https://example.com/default-time.png";
        uint256 maxSupply = 50;
        bool mintPerWallet = true;
        uint256 mintPrice = 0.005 ether;

        // Create a collection with default time
        address collectionAddress = factory.createCollection(
            name,
            description,
            "v1", "cartone",
            symbol,
            imageURL,
            maxSupply,
            block.timestamp + 7 days,
            mintPerWallet,
            mintPrice,
            false,
            false
        );

        // Verify the collection was deployed with default maxTime
        NFTCollection collection = NFTCollection(collectionAddress);
        uint256 expectedMaxTime = block.timestamp + 7 days; // 1 week
        assertEq(collection.maxTime(), expectedMaxTime);
    }

    function testGetAvailableCollectionsDetails() public {
        // Create two collections
        address collection1 = factory.createCollection(
            "Collection 1",
            "Description 1",  "v1", "cartone",
            "COL1",
            "https://example.com/image1.png",
            100,
            block.timestamp + 365 days,
            true,
            0.01 ether,
            false,
            false
        );

        address collection2 = factory.createCollection(
            "Collection 2",
            "Description 2",  "v2", "cartone2",
            "COL2",
            "https://example.com/image2.png",
            200,
            block.timestamp + 730 days,
            true,
            0.02 ether,
            false,
            false
        );

        // Set both collections to visible
        // NFTCollection(collection1).setCanShow(true);
        // NFTCollection(collection2).setCanShow(true);

        // Get available collection details
        AIBasedNFTFactory.CollectionDetails[] memory details = getAvailableCollectionsToMintDetails();

        // Verify details of the first collection
        assertEq(details.length, 2);
        assertEq(details[0].collectionAddress, collection1);
        assertEq(details[0].tokenIdCounter, 0);
        assertEq(details[0].maxSupply, 100);
        assertEq(details[0].baseImageURI, "https://example.com/image1.png");
        assertEq(details[0].maxTime, block.timestamp + 365 days);

        // Verify details of the second collection
        assertEq(details[1].collectionAddress, collection2);
        assertEq(details[1].tokenIdCounter, 0);
        assertEq(details[1].maxSupply, 200);
        assertEq(details[1].baseImageURI, "https://example.com/image2.png");
        assertEq(details[1].maxTime, block.timestamp + 730 days);

        vm.warp(block.timestamp + 366 days); 

            AIBasedNFTFactory.CollectionDetails[] memory avaiableColloctions = getAvailableCollectionsToMintDetails();
            assertEq(avaiableColloctions.length, 1);
            assertEq(avaiableColloctions[0].collectionAddress, details[1].collectionAddress);
    }



    // Test retrieving details for a collection with ultimate mint conditions
    function testGetDetailsWithMillionsOFCollections() public {
        vm.pauseGasMetering();
        uint256 length = 10_000;
        for (uint256 i = 0; i < length; i++) {
            // Create a time-sensitive collection (last hour)
            createTestCollection(owner, 1000, type(uint256).max, false);
        }
        // vm.resumeGasMetering();
        address[] memory details = factory.getCollections();
        AIBasedNFTFactory.CollectionDetails[] memory detailsCollectios = getAvailableCollectionsToMintDetails();
        assertEq(details.length, length);
        assertEq(detailsCollectios.length, length);
    }


    
    function testMintFeeToCreatorAccount() public {
        address creatorUser = address(0x2000);
        vm.deal(creatorUser, 0.1 ether);
        uint256 creatorUserBalanceBefore = creatorUser.balance;

        address minterUser = address(0x2100);
        vm.deal(minterUser, 0.3 ether);
        uint256 minterUserBalanceBefore = minterUser.balance;

        uint256 nftPrice = 0.002 ether;
        uint256 nftFee = 0.0001 ether;

        uint256 ownerBalanceBefore = owner.balance;

        vm.startPrank(creatorUser);
        // Create a  collection
        address collection = factory.createCollection("Restricted Collection", 
        "A restricted collection",   "v1", "cartone",
        "RCOL", 
        "https://example.com/restricted.png", 
        10, 
        block.timestamp + 7 days,
        false, 
        nftPrice, 
        false, false);

        vm.stopPrank();
        
        // Mint from restricted collection to trigger wallet restriction
        uint256 mintPrice = nftPrice + nftFee;
        uint256 totalNFTValue = mintPrice * 3;
        vm.startPrank(minterUser);
        factory.mintNFT{value: totalNFTValue}(collection, minterUser, 3);

        NFTCollection nftCollection = NFTCollection(collection);
        // Verify balances
        assertEq(nftCollection.totalSupply(), 3, "Mint failed");
        assertEq(nftCollection.maxSupply(), 10, "Mint failed");
        assertEq(minterUser.balance, minterUserBalanceBefore - totalNFTValue, "User ETH not deducted");
        assertEq(collection.balance, (nftFee * 3), "User ETH not deducted");
        assertEq(creatorUser.balance, creatorUserBalanceBefore + (nftPrice * 3), "Owner didn't receive ETH");
        vm.stopPrank();

        vm.startPrank(owner);
        nftCollection.withdraw();
        
        assertEq(owner.balance, ownerBalanceBefore + (nftFee * 3), "Owner should receive contract balance");
        assertEq(collection.balance, 0, "User ETH not deducted");
    }

    function testCollectionFee() public {
    
        uint nftFee = 0.001 ether;
        uint platformFee = 0.0001 ether;
        vm.deal(user, 1 ether);
        vm.deal(user2, 1 ether);
        vm.startPrank(user);
        factory.createCollection(
            "AdminTest", "Desc",  "v1", "cartone", "ADM", "ipfs://admin", 
            100, defaultMaxTime, false, nftFee, false, false
        );
        // NFTCollection collection = NFTCollection(collectionAddress);
        
        // Test admin-only functions with non-admin
        
        AIBasedNFTFactory.CollectionDetails[] memory detailsGeneral = getAvailableCollectionsToMintDetails();
        AIBasedNFTFactory.CollectionDetails[] memory detailsUser1 = getAvailableCollectionsToMintDetails(user);
        AIBasedNFTFactory.CollectionDetails[] memory detailsUser2 = getAvailableCollectionsToMintDetails(user2);
        
        
        assertEq(detailsGeneral[0].mintPrice, nftFee + platformFee);
        assertEq(detailsUser1[0].mintPrice, nftFee + platformFee);
        assertEq(detailsUser1[0].actualPrice, platformFee);
        assertEq(detailsUser2[0].mintPrice, nftFee + platformFee);
        assertEq(detailsUser2[0].actualPrice, nftFee + platformFee);

    }

}