// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";


contract NFTFactory is Ownable {
    address[] public deployedCollections;
    
    constructor() Ownable(msg.sender) {} 
    
    event CollectionCreated(
        address indexed collection,
        string name,
        string description,
        string symbol,
        uint256 maxSupply,
        uint256 maxTime,
        string imageURL,
        bool mintPerWallet,
        uint256 mintPrice,
        address owner
    );

     // Struct to hold collection details
    struct CollectionDetails {
        address collectionAddress;
        uint256 tokenIdCounter;
        uint256 maxSupply;
        string baseImageURI;
        bool revealed;
        string unrevealedURI;
        uint256 maxTime;
        bool mintPerWallet;
        uint256 mintPrice;
        bool isDisable;
    }

    function createCollection(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        uint256 maxSupply,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
        NFTCollection collection = new NFTCollection(
            name,
            description,
            symbol,
            maxSupply,
            maxTime,
            imageURL,
            mintPerWallet,
            mintPrice,
            owner(),
            msg.sender
        );
        
        deployedCollections.push(address(collection));
        emit CollectionCreated(address(collection), name, description, symbol, maxSupply, maxTime, imageURL, mintPerWallet, mintPrice, msg.sender);
        return address(collection);
    }

    function createWithDefaultCollectionWithDefaultTime(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        uint256 maxSupply,
        bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
        
        /// @dev Default maxTime is 168 hours equal to 1 week 
        uint256 maxTime=  block.timestamp + (60*60*24*7);
        return createCollection(name, description, symbol, imageURL, maxSupply, maxTime, mintPerWallet, mintPrice);
    }

    function createWithDefaultCollectionWithMaxSupply(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
        
        /// @dev Default maxSupply is max uint256
        uint256 maxSupply=  type(uint256).max;
        return createCollection(name, description, symbol, imageURL, maxSupply, maxTime, mintPerWallet, mintPrice);
        }

        function createWithDefaultCollectionWithMaxSupplyAndDefaultTime(
            string memory name,
            string memory description,
            string memory symbol,
            string memory imageURL,
            bool mintPerWallet,
        uint256 mintPrice) public returns (address) {
            
            /// @dev Default maxTime is 168 hours equal to 1 week 
            uint256 maxTime=  block.timestamp + (60*60*24*7);
            /// @dev Default maxSupply is max uint256
            uint256 maxSupply=  type(uint256).max;
            return createCollection(name, description, symbol, imageURL, maxSupply, maxTime, mintPerWallet, mintPrice);
        }


    function createAndMint(
            string memory name,
            string memory description,
            string memory symbol,
            string memory imageURL,
            bool mintPerWallet,
            uint256 mintPrice) public payable {
            
            /// @dev Default maxTime is 168 hours equal to 1 week 
            uint256 maxTime=  168;
            /// @dev Default maxSupply is max uint256
            uint256 maxSupply=  type(uint256).max;


            NFTCollection collection = new NFTCollection(
                        name,
                        description,
                        symbol,
                        1,
                        block.timestamp + 60,
                        imageURL,
                        true,
                        0.0001 ether,
                        owner(),
                        msg.sender
                    );
        
        emit CollectionCreated(address(collection), name, description, symbol, maxSupply, maxTime, imageURL, mintPerWallet, mintPrice, msg.sender);
        collection.mintNFT{value: msg.value}(msg.sender, 1);
    }

    function getCollections() public view returns (address[] memory) {

        return deployedCollections;
    }

     // function to retrieve all collection details with sender
    function getAllCollectionsDetails(address sender) public view returns (CollectionDetails[] memory) {
        uint256 length = deployedCollections.length;
        CollectionDetails[] memory details = new CollectionDetails[](length);
        
        for (uint256 i = 0; i < length; i++) {
            address collectionAddress = deployedCollections[i];
            NFTCollection collection = NFTCollection(collectionAddress);
            
            details[i] = CollectionDetails({
                collectionAddress: collectionAddress,
                tokenIdCounter: collection.totalSupply(),
                maxSupply: collection.maxSupply(),
                baseImageURI: collection.imageURL(),
                revealed: collection.revealed(),
                unrevealedURI: collection.unrevealedURI(),
                maxTime: collection.maxTime(),
                mintPerWallet: collection.mintPerWallet(),
                mintPrice: collection.mintPrice(),
                isDisable: collection.isDisabled(sender)
            });
        }
        
        return details;
    }

      // function to retrieve all collection details
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
                baseImageURI: collection.imageURL(),
                revealed: collection.revealed(),
                unrevealedURI: collection.unrevealedURI(),
                maxTime: collection.maxTime(),
                mintPerWallet: collection.mintPerWallet(),
                mintPrice: collection.mintPrice(),
                isDisable: true
            });
        }
        
        return details;
    }
}