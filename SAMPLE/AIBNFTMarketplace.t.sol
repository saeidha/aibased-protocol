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
