// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";


contract NFTFactory is Ownable {
    address[] public deployedCollections;
    
    uint256 private generateFee = 0 ether;

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
        uint256 maxTime;
        bool mintPerWallet;
        uint256 mintPrice;
        bool isDisable;
        bool isUltimateMintTime;
        bool isUltimateMintQuantity;
    }

    function createCollection(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        uint256 maxSupply,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice,
        bool isUltimateMintTime,
        bool isUltimateMintQuantity) public returns (address) {
            
        NFTCollection collection = new NFTCollection(
            name,
            description,
            symbol,
            isUltimateMintQuantity ? type(uint256).max : maxSupply,
            isUltimateMintTime ? type(uint256).max : maxTime,
            imageURL,
            mintPerWallet,
            mintPrice,
            owner(),
            msg.sender
        );
        
        deployedCollections.push(address(collection));
        emit CollectionCreated(address(collection),
            name,
            description, 
            symbol, 
            isUltimateMintQuantity ? type(uint256).max : maxSupply,
            isUltimateMintTime ? type(uint256).max : maxTime,
            imageURL, 
            mintPerWallet, 
            mintPrice, 
            msg.sender);
        return address(collection);
    }

    function createWithDefaultCollectionWithDefaultTime(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        uint256 maxSupply,
        bool mintPerWallet,
        uint256 mintPrice,
        bool isUltimateMintQuantity) public returns (address) {
        
        /// @dev Default maxTime is 168 hours equal to 1 week 
        uint256 maxTime=  block.timestamp + (60*60*24*7);
        return createCollection(name, description, symbol, imageURL, maxSupply, maxTime, mintPerWallet, mintPrice, false, isUltimateMintQuantity);
    }

    function createWithDefaultCollectionWithMaxSupply(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice,
        bool isUltimateMintTime) public returns (address) {
        
        /// @dev Default maxSupply is max uint256
        uint256 maxSupply=  type(uint256).max;
        return createCollection(name, description, symbol, imageURL, maxSupply, maxTime, mintPerWallet, mintPrice, isUltimateMintTime, true);
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
            return createCollection(name, description, symbol, imageURL, maxSupply, maxTime, mintPerWallet, mintPrice, false, true);
        }


    function createAndMint(
            string memory name,
            string memory description,
            string memory symbol,
            string memory imageURL) public payable {
            
            /// @dev Default maxTime is 1 hours
            uint256 maxTime=  block.timestamp + 60 * 60;
            /// @dev Default maxSupply is 1
            uint256 maxSupply=  1;


            NFTCollection collection = new NFTCollection(
                        name,
                        description,
                        symbol,
                        maxSupply,
                        maxTime,
                        imageURL,
                        true,
                        0,
                        owner(),
                        msg.sender
                    );
        
        emit CollectionCreated(address(collection), name, description, symbol, maxSupply, maxTime, imageURL, true, 0, msg.sender);
        collection.mintNFT{value: msg.value}(msg.sender, 1);
    }

    function getCollections() public view returns (address[] memory) {

        return deployedCollections;
    }








    // function to retrieve all collection details with sender
    function getAvailableCollectionDetailsByContractAddress(address contractAddress) public view returns (CollectionDetails memory) {

        for (uint256 i = 0; i < deployedCollections.length; i++) {
            NFTCollection collection = NFTCollection(deployedCollections[i]);

            if (deployedCollections[i] == contractAddress) {
                return CollectionDetails({
                    collectionAddress: deployedCollections[i],
                    tokenIdCounter: collection.totalSupply(),
                    maxSupply: collection.maxSupply(),
                    baseImageURI: collection.imageURL(),
                    maxTime: collection.maxTime(),
                    mintPerWallet: collection.mintPerWallet(),
                    mintPrice: collection.mintPrice(),
                    isDisable: true,
                    isUltimateMintTime: collection.isUltimateMintTime(),
                    isUltimateMintQuantity: collection.isUltimateMintQuantity()
                });
            }
        }

        // Return an empty CollectionDetails struct if not found
    return CollectionDetails({
        collectionAddress: address(0),
        tokenIdCounter: 0,
        maxSupply: 0,
        baseImageURI: "",
        maxTime: 0,
        mintPerWallet: false,
        mintPrice: 0,
        isDisable: false,
        isUltimateMintTime: false,
        isUltimateMintQuantity: false
    });
    }


    // function to retrieve all collection details with sender
    function getAvailableCollectionDetailsByContractAddress(address contractAddress, address sender) public view returns (CollectionDetails memory) {

        for (uint256 i = 0; i < deployedCollections.length; i++) {
            NFTCollection collection = NFTCollection(deployedCollections[i]);

            if (deployedCollections[i] == contractAddress) {
                return CollectionDetails({
                    collectionAddress: deployedCollections[i],
                    tokenIdCounter: collection.totalSupply(),
                    maxSupply: collection.maxSupply(),
                    baseImageURI: collection.imageURL(),
                    maxTime: collection.maxTime(),
                    mintPerWallet: collection.mintPerWallet(),
                    mintPrice: collection.mintPrice(),
                    isDisable: collection.isDisabled(sender),
                    isUltimateMintTime: collection.isUltimateMintTime(),
                    isUltimateMintQuantity: collection.isUltimateMintQuantity()
                });
            }
        }

        // Return an empty CollectionDetails struct if not found
    return CollectionDetails({
        collectionAddress: address(0),
        tokenIdCounter: 0,
        maxSupply: 0,
        baseImageURI: "",
        maxTime: 0,
        mintPerWallet: false,
        mintPrice: 0,
        isDisable: false,
        isUltimateMintTime: false,
        isUltimateMintQuantity: false
    });
    }

     // function to retrieve all collection details with sender
    function getAvailableCollectionsDetails(address sender) public view returns (CollectionDetails[] memory) {
         uint256 length = deployedCollections.length;

        // Use a dynamic memory array and then copy it to a fixed-size array to save gas.
        CollectionDetails[] memory tempDetails = new CollectionDetails[](length);
        uint256 count = 0;

        for (uint256 i = 0; i < length; i++) {
            NFTCollection collection = NFTCollection(deployedCollections[i]);

            if (collection.canShow()) {
                tempDetails[count] = CollectionDetails({
                    collectionAddress: deployedCollections[i],
                    tokenIdCounter: collection.totalSupply(),
                    maxSupply: collection.maxSupply(),
                    baseImageURI: collection.imageURL(),
                    maxTime: collection.maxTime(),
                    mintPerWallet: collection.mintPerWallet(),
                    mintPrice: collection.mintPrice(),
                    isDisable: collection.isDisabled(sender),
                    isUltimateMintTime: collection.isUltimateMintTime(),
                    isUltimateMintQuantity: collection.isUltimateMintQuantity()
                });
                count++;
            }
        }

        // Create the final fixed-size array with the exact count
        CollectionDetails[] memory details = new CollectionDetails[](count);
        for (uint256 i = 0; i < count; i++) {
            details[i] = tempDetails[i];
        }

        return details;
    }

      // function to retrieve all collection details
    function getAvailableCollectionsDetails() public view returns (CollectionDetails[] memory) {
         uint256 length = deployedCollections.length;

        // Use a dynamic memory array and then copy it to a fixed-size array to save gas.
        CollectionDetails[] memory tempDetails = new CollectionDetails[](length);
        uint256 count = 0;

        for (uint256 i = 0; i < length; i++) {
            NFTCollection collection = NFTCollection(deployedCollections[i]);

            if (collection.canShow()) {
                tempDetails[count] = CollectionDetails({
                    collectionAddress: deployedCollections[i],
                    tokenIdCounter: collection.totalSupply(),
                    maxSupply: collection.maxSupply(),
                    baseImageURI: collection.imageURL(),
                    maxTime: collection.maxTime(),
                    mintPerWallet: collection.mintPerWallet(),
                    mintPrice: collection.mintPrice(),
                    isDisable: true,
                    isUltimateMintTime: collection.isUltimateMintTime(),
                    isUltimateMintQuantity: collection.isUltimateMintQuantity()
                });
                count++;
            }
        }

        // Create the final fixed-size array with the exact count
        CollectionDetails[] memory details = new CollectionDetails[](count);
        for (uint256 i = 0; i < count; i++) {
            details[i] = tempDetails[i];
        }

        return details;
    }


    /// get all collection for a address
    function getAllCollectionsForDetails(address sender) public view returns (CollectionDetails[] memory) {
         uint256 length = deployedCollections.length;

        // Use a dynamic memory array and then copy it to a fixed-size array to save gas.
        CollectionDetails[] memory tempDetails = new CollectionDetails[](length);
        uint256 count = 0;

        for (uint256 i = 0; i < length; i++) {
            NFTCollection collection = NFTCollection(deployedCollections[i]);

            if (collection.owner() == sender) {
                tempDetails[count] = CollectionDetails({
                    collectionAddress: deployedCollections[i],
                    tokenIdCounter: collection.totalSupply(),
                    maxSupply: collection.maxSupply(),
                    baseImageURI: collection.imageURL(),
                    maxTime: collection.maxTime(),
                    mintPerWallet: collection.mintPerWallet(),
                    mintPrice: collection.mintPrice(),
                    isDisable: collection.isDisabled(sender),
                    isUltimateMintTime: collection.isUltimateMintTime(),
                    isUltimateMintQuantity: collection.isUltimateMintQuantity()
                });
                count++;
            }
        }

        // Create the final fixed-size array with the exact count
        CollectionDetails[] memory details = new CollectionDetails[](count);
        for (uint256 i = 0; i < count; i++) {
            details[i] = tempDetails[i];
        }

        return details;
    }

    function payGenerateFee() public payable returns (bool) {

        require(msg.value >= generateFee, "Payable: msg.value must be equal to amount");
        return true;
        
    }

    /////-------- ADMIN --------------/////
    /// function
    function withdraw() public {

        require(msg.sender == owner(), "Only admin");
        payable(owner()).transfer(address(this).balance);
    }

    function setGenerateFee(uint256 _newFee) public { 

        require(msg.sender == owner(), "Only admin");
        generateFee = _newFee;
    }


    function getFee() public view returns (uint256) {

        require(msg.sender == owner(), "Only admin");
        
        return generateFee;
    }
}