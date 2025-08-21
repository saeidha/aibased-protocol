// File: test/AIBNFTMarketplace.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AIBNFTMarketplace.sol"; // Adjust path if needed
import "../src/MockNFT.sol"; // Adjust path if needed

contract AIBNFTMarketplaceTest is Test {
    //=========== State Variables ===========//
    AIBNFTMarketplace marketplace;
    MockNFT mockNft;
    address owner = makeAddr("owner");
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");

     uint256 constant LISTING_FEE = 0.01 ether;
    uint256 constant NFT_PRICE = 1 ether;
    uint256 constant TOKEN_ID = 0;
    uint256 constant TOKEN_ID_s = 0;
    
    //=========== Setup ===========//

    /// @notice This function runs before each test case
    function setUp() public {
        // Deploy contracts as the
        vm.startPrank(owner);
        mockNft = new MockNFT();
        marketplace = new AIBNFTMarketplace(LISTING_FEE);
        vm.stopPrank();
 // Mint an NFT (Token ID 0) to the seller
        mockNft.mint(seller);
// Seller must approve the marketplace to manage the NFT
        vm.prank(seller);
        mockNft.approve(address(marketplace), TOKEN_ID);
 // Give the buyer some ETH for tests
        vm.deal(buyer, 5 ether);
    }

    //=========== Test Functions ===========//

    // --- Deployment Tests ---
    function test_Deployment_SetsCorrectOwnerAndFee() public {
        assertEq(marketplace.owner(), owner, "Owner should be set correctly");
        assertEq(marketplace.getListingFee(), LISTING_FEE, "Listing fee should be set correctly");
    }

         // --- Listing Tests ---
    function test_Fail_ListNFT_WhenPaused() public {

         vm.prank(owner);
        marketplace.pause();
vm.prank(seller);
        bytes memory expectedRevert = abi.encodeWithSelector(Pausable.EnforcedPause.selector);
          vm.expectRevert(expectedRevert);
        marketplace.listNFT{value: LISTING_FEE}(address(mockNft), TOKEN_ID, NFT_PRICE);
    }
    function test_Fail_ListNFT_WithoutListingFee() public {
        vm.prank(seller);
         vm.expectRevert("Incorrect listing fee paid.");
        marketplace.listNFT(address(mockNft), TOKEN_ID, NFT_PRICE);
    }

    function test_Fail_ListNFT_WithoutApproval() public {
         uint256 newTokenId = mockNft.mint(seller); // A new token without approval
         vm.prank(seller);
         vm.expectRevert("Marketplace not approved for this NFT.");
        marketplace.listNFT{value: LISTING_FEE}(address(mockNft), newTokenId, NFT_PRICE);
    }

    function test_ListNFT_Success() public {
          vm.prank(seller);
        
        vm.expectEmit(true, true, true, true);
        emit NFTListed(seller, address(mockNft), TOKEN_ID, NFT_PRICE);
        marketplace.listNFT{value: LISTING_FEE}(address(mockNft), TOKEN_ID, NFT_PRICE);

        // Verify NFT is now owned (locked) by the marketplace
        assertEq(mockNft.ownerOf(TOKEN_ID), address(marketplace), "Marketplace should own the NFT");
        
    }