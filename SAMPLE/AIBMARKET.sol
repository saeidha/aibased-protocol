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
