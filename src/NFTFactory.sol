// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";


contract NFTFactory is Ownable {
    address[] public deployedCollections;
    
    constructor() Ownable(msg.sender) {} 
    
    event CollectionCreated(
        address indexed collection,
        string name,
        string symbol,
        uint256 maxSupply,
        uint256 maxTime,
        string baseURI,
        bool mintPerWallet,
        uint256 mintPrice,
        address owner
    );

     // Struct to hold collection details
    struct CollectionDetails {
        address collectionAddress;
        uint256 tokenIdCounter;
        uint256 maxSupply;
        string baseTokenURI;
        bool revealed;
        string unrevealedURI;
        uint256 maxTime;
        bool mintPerWallet;
        uint256 mintPrice;
    }

    function createCollection(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 maxSupply,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
        NFTCollection collection = new NFTCollection(
            name,
            symbol,
            maxSupply,
            maxTime,
            baseURI,
            mintPerWallet,
            mintPrice,
            msg.sender
        );
        
        deployedCollections.push(address(collection));
        emit CollectionCreated(address(collection), name, symbol, maxSupply, maxTime, baseURI, mintPerWallet, mintPrice, msg.sender);
        return address(collection);
    }

    function createWithDefaultCollectionWithDefaultTime(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 maxSupply,
        bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
        
        /// @dev Default maxTime is 168 hours equal to 1 week 
        uint256 maxTime=  168;
        return createCollection(name, symbol, baseURI, maxSupply, maxTime, mintPerWallet, mintPrice);
    }

    function createWithDefaultCollectionWithMaxSupply(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
        
        /// @dev Default maxSupply is max uint256
        uint256 maxSupply=  type(uint256).max;
        return createCollection(name, symbol, baseURI, maxSupply, maxTime, mintPerWallet, mintPrice);
        }

        function createWithDefaultCollectionWithMaxSupplyAndDefaultTime(
            string memory name,
            string memory symbol,
            string memory baseURI,
            bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
            
            /// @dev Default maxTime is 168 hours equal to 1 week 
            uint256 maxTime=  168;
            /// @dev Default maxSupply is max uint256
            uint256 maxSupply=  type(uint256).max;
            return createCollection(name, symbol, baseURI, maxSupply, maxTime, mintPerWallet, mintPrice);
            }

    function getCollections() public view returns (address[] memory) {

        return deployedCollections;
    }

     // New function to retrieve all collection details
    function getAllCollectionsDetails() public view returns (CollectionDetails[] memory) {
        uint256 length = deployedCollections.length;
        CollectionDetails[] memory details = new CollectionDetails[](length);
        
        for (uint256 i = 0; i < length; i++) {
            address collectionAddress = deployedCollections[i];
            NFTCollection collection = NFTCollection(collectionAddress);
            
            details[i] = CollectionDetails({
                collectionAddress: collectionAddress,
                tokenIdCounter: collection.totalSupply(),
                maxSupply: collection.maxSupply(),
                baseTokenURI: collection.baseTokenURI(),
                revealed: collection.revealed(),
                unrevealedURI: collection.unrevealedURI(),
                maxTime: collection.maxTime(),
                mintPerWallet: collection.mintPerWallet(),
                mintPrice: collection.mintPrice()
            });
        }
        
        return details;
    }
}