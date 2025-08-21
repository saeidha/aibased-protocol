// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


/**
 * @title AIBNFTMarketplace
 * @dev A simple marketplace for listing, buying, and selling ERC721 NFTs.
 */
contract AIBNFTMarketplace is Pausable, Ownable, ERC721Holder {

//=========== State Variables ===========//

    struct Listing {
        address seller;
        uint256 price;
    }
    // Mapping: NFT Contract Address -> Token ID -> Listing Details
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    uint256 private s_listingFee;

    //=========== Events ===========//
    event NFTListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );
event NFTSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );
event NFTListingCancelled(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    event NFTPriceUpdated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    event ListingFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed owner, uint256 amount);

//=========== Modifiers ==========//

    modifier isListed(address nftContract, uint256 tokenId) {
        if (s_listings[nftContract][tokenId].price <= 0) {
            revert("NFT not listed for sale.");
        }
        _;
    }

    modifier isSeller(address nftContract, uint256 tokenId, address spender) {
        if (s_listings[nftContract][tokenId].seller != spender) {
            revert("You are not the seller of this NFT.");
        }
        _;
    }

    //=========== Constructor ===========//

    constructor(uint256 initialListingFee) Ownable(msg.sender) {
        s_listingFee = initialListingFee;
    }

    //=========== Core Marketplace Functions ===========//
    /**
     * @notice Lists an NFT for sale. The contract must be approved to manage the NFT.
     * @dev Locks the NFT in the contract until sale or cancellation.
     * @param _nftContract The address of the ERC721 token contract.
     * @param _tokenId The ID of the token to list.
     * @param _price The selling price in wei (must be > 0).
     */
        function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external payable whenNotPaused {
        require(_price > 0, "Price must be greater than zero.");
        require(msg.value == s_listingFee, "Incorrect listing fee paid.");

 IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "You do not own this NFT.");
        require(nft.getApproved(_tokenId) == address(this), "Marketplace not approved for this NFT.");
// Lock the NFT by transferring it to this contract
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        s_listings[_nftContract][_tokenId] = Listing(msg.sender, _price);
        emit NFTListed(msg.sender, _nftContract, _tokenId, _price);
    }

    /**
     * @notice Buys a listed NFT.
     * @dev Buyer must send ETH equal to or greater than the listing price.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The ID of the token to buy.
     */
    function buyNFT(address _nftContract, uint256 _tokenId) external payable whenNotPaused isListed(_nftContract, _tokenId) {
        Listing memory listing = s_listings[_nftContract][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to purchase.");
         delete s_listings[_nftContract][_tokenId];
        (bool success, ) = listing.seller.call{value: listing.price}("");
        require(success, "Failed to transfer funds to seller.");
         IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Refund excess ETH, if any
        if (msg.value > listing.price) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - listing.price}("");
            // We do not require refund success to prevent transaction failure
        }
        emit NFTSold(listing.seller, msg.sender, _nftContract, _tokenId, listing.price);
    }

    /**
     * @notice Cancels an active NFT listing.
     * @dev The locked NFT is returned to the seller.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The ID of the token to delist.
     */
    function cancelListing(address _nftContract, uint256 _tokenId) 
        external whenNotPaused isListed(_nftContract, _tokenId) isSeller(_nftContract, _tokenId, msg.sender) 
    {
        delete s_listings[_nftContract][_tokenId];
        IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit NFTListingCancelled(msg.sender, _nftContract, _tokenId);
    }

    /**
     * @notice Updates the price of a listed NFT.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The ID of the token.
     * @param _newPrice The new price for the NFT in wei.
     */
    function updatePrice(address _nftContract, uint256 _tokenId, uint256 _newPrice) 
        external whenNotPaused isListed(_nftContract, _tokenId) isSeller(_nftContract, _tokenId, msg.sender) 
    {
        require(_newPrice > 0, "Price must be greater than zero.");
        s_listings[_nftContract][_tokenId].price = _newPrice;
        emit NFTPriceUpdated(msg.sender, _nftContract, _tokenId, _newPrice);
    }

    //=========== Admin Functions ===========//
    function updateListingFee(uint256 _newFee) external onlyOwner {
       
    }