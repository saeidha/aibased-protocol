// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./NFTCollection.sol";

contract NFTFactory is Ownable {
    address[] public deployedCollections;
    address[] public mintPadCollections;

    mapping(address => address[]) private _usersCollections;
    mapping(address => address[]) private _usersMint;

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
        string name;
        string description;
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

    //// ------------------------------CREATE COLLECTION------------------------------ ////
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
        bool isUltimateMintQuantity
    ) public returns (address) {
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
        mintPadCollections.push(address(collection));
        addUsersCollections(msg.sender, address(collection));
        emit CollectionCreated(
            address(collection),
            name,
            description,
            symbol,
            isUltimateMintQuantity ? type(uint256).max : maxSupply,
            isUltimateMintTime ? type(uint256).max : maxTime,
            imageURL,
            mintPerWallet,
            mintPrice,
            msg.sender
        );
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
        bool isUltimateMintQuantity
    ) public returns (address) {
        /// @dev Default maxTime is 168 hours equal to 1 week
        uint256 maxTime = block.timestamp + (60 * 60 * 24 * 7);
        return
            createCollection(
                name,
                description,
                symbol,
                imageURL,
                maxSupply,
                maxTime,
                mintPerWallet,
                mintPrice,
                false,
                isUltimateMintQuantity
            );
    }

    function createWithDefaultCollectionWithMaxSupply(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice,
        bool isUltimateMintTime
    ) public returns (address) {
        /// @dev Default maxSupply is max uint256
        uint256 maxSupply = type(uint256).max;
        return
            createCollection(
                name,
                description,
                symbol,
                imageURL,
                maxSupply,
                maxTime,
                mintPerWallet,
                mintPrice,
                isUltimateMintTime,
                true
            );
    }

    function createWithDefaultCollectionWithMaxSupplyAndDefaultTime(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL,
        bool mintPerWallet,
        uint256 mintPrice
    ) public returns (address) {
        /// @dev Default maxTime is 168 hours equal to 1 week
        uint256 maxTime = block.timestamp + (60 * 60 * 24 * 7);
        /// @dev Default maxSupply is max uint256
        uint256 maxSupply = type(uint256).max;
        return
            createCollection(
                name,
                description,
                symbol,
                imageURL,
                maxSupply,
                maxTime,
                mintPerWallet,
                mintPrice,
                false,
                true
            );
    }

    function createAndMint(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL
    ) public payable {
        /// @dev Default maxTime is 1 hours
        uint256 maxTime = block.timestamp + 60 * 60;
        /// @dev Default maxSupply is 1
        uint256 maxSupply = 1;

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

        address collectionAddress = address(collection);
        deployedCollections.push(collectionAddress);
        addUsersMints(msg.sender, collectionAddress);
        emit CollectionCreated(
            collectionAddress,
            name,
            description,
            symbol,
            maxSupply,
            maxTime,
            imageURL,
            true,
            0,
            msg.sender
        );
        collection.mintNFT{value: msg.value}(msg.sender, 1);
    }

    //// ------------------------------------------------------------ ////

    //// ---------------------------MINT--------------------------- ////

    function mintNFT(
        address collectionAddress,
        address to,
        uint256 quantity
    ) public payable {
        NFTCollection collection = NFTCollection(collectionAddress);
        collection.mintNFT{value: msg.value}(to, quantity);

        bool isExist = false;
        uint256 length = getUserCollectionsCount(to);
        address[] memory usersCollection = _usersCollections[to];

        for (uint256 i = 0; i < length; i++) {
            if (collectionAddress == usersCollection[i]) {
                addUsersMints(to, collectionAddress);
                isExist = true;
                return;
            }
        }
        if (!isExist) {
            addUsersMints(to, collectionAddress);
        }
    }

    //// ------------------------------------------------------------ ////

    ///// --------------------------- Collection GETTERS --------------------------- ////
    function getCollections() public view returns (address[] memory) {
        return deployedCollections;
    }

    function getMintPadCollections() public view returns (address[] memory) {
        return mintPadCollections;
    }

    ///// --------------- RETRIEVE ALL AVAILABLE COLLECTION DETAILS --------- ////
    // function to retrieve all available collection details
    function getAvailableCollectionsToMintDetails()
        public
        view
        returns (CollectionDetails[] memory)
    {
        uint256 length = mintPadCollections.length;

        // Use a dynamic memory array and then copy it to a fixed-size array to save gas.
        CollectionDetails[] memory tempDetails = new CollectionDetails[](
            length
        );
        uint256 count = 0;

        for (uint256 i = 0; i < length; i++) {
            NFTCollection collection = NFTCollection(mintPadCollections[i]);

            if (!collection.canNotToShow()) {
                tempDetails[count] = CollectionDetails({
                    collectionAddress: mintPadCollections[i],
                    name: collection.name(),
                    description: collection.description(),
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

    // function to retrieve all available collection details with sender address
    function getAvailableCollectionsToMintDetails(
        address sender
    ) public view returns (CollectionDetails[] memory) {
        uint256 length = mintPadCollections.length;

        // Use a dynamic memory array and then copy it to a fixed-size array to save gas.
        CollectionDetails[] memory tempDetails = new CollectionDetails[](
            length
        );
        uint256 count = 0;

        for (uint256 i = 0; i < length; i++) {
            NFTCollection collection = NFTCollection(mintPadCollections[i]);

            if (!collection.canNotToShow()) {
                tempDetails[count] = CollectionDetails({
                    collectionAddress: mintPadCollections[i],
                    name: collection.name(),
                    description: collection.description(),
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

    ///// -------------------------------------------------------------------------- ////

    ///// --------------- RETRIEVE USER COLLECTION DETAILS --------- ////
    // function to retrieve user collection details with sender address
    function getUserCollectionsDetails(
        address sender
    ) public view returns (CollectionDetails[] memory) {
        uint256 length = _usersCollections[sender].length;

        // Use a dynamic memory array and then copy it to a fixed-size array to save gas.
        CollectionDetails[] memory details = new CollectionDetails[](length);

        for (uint256 i = 0; i < length; i++) {
            NFTCollection collection = NFTCollection(
                _usersCollections[sender][i]
            );

            if (collection.owner() == sender) {
                details[i] = CollectionDetails({
                    collectionAddress: _usersCollections[sender][i],
                    name: collection.name(),
                    description: collection.description(),
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

        return details;
    }

    ///// -------------------------------------------------------------------------- ////

    ///// --------------- RETRIEVE SPECIFIC COLLECTION DETAILS BY CONTRACT ADDRESS --------- ////
    /// function to retrieve specefic available collection details by contract address
    function getCollectionDetailsByContractAddress(
        address contractAddress
    ) public view returns (CollectionDetails memory) {
        for (uint256 i = 0; i < deployedCollections.length; i++) {
            NFTCollection collection = NFTCollection(deployedCollections[i]);

            if (deployedCollections[i] == contractAddress) {
                return
                    CollectionDetails({
                        collectionAddress: deployedCollections[i],
                        name: collection.name(),
                        description: collection.description(),
                        tokenIdCounter: collection.totalSupply(),
                        maxSupply: collection.maxSupply(),
                        baseImageURI: collection.imageURL(),
                        maxTime: collection.maxTime(),
                        mintPerWallet: collection.mintPerWallet(),
                        mintPrice: collection.mintPrice(),
                        isDisable: true,
                        isUltimateMintTime: collection.isUltimateMintTime(),
                        isUltimateMintQuantity: collection
                            .isUltimateMintQuantity()
                    });
            }
        }

        // Return an empty CollectionDetails struct if not found
        return
            CollectionDetails({
                collectionAddress: address(0),
                name: "",
                description: "",
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

    /// function to retrieve specefic available collection details by contract address
    function getCollectionDetailsByContractAddress(
        address contractAddress,
        address sender
    ) public view returns (CollectionDetails memory) {
        for (uint256 i = 0; i < deployedCollections.length; i++) {
            NFTCollection collection = NFTCollection(deployedCollections[i]);

            if (deployedCollections[i] == contractAddress) {
                return
                    CollectionDetails({
                        collectionAddress: deployedCollections[i],
                        name: collection.name(),
                        description: collection.description(),
                        tokenIdCounter: collection.totalSupply(),
                        maxSupply: collection.maxSupply(),
                        baseImageURI: collection.imageURL(),
                        maxTime: collection.maxTime(),
                        mintPerWallet: collection.mintPerWallet(),
                        mintPrice: collection.mintPrice(),
                        isDisable: collection.isDisabled(sender),
                        isUltimateMintTime: collection.isUltimateMintTime(),
                        isUltimateMintQuantity: collection
                            .isUltimateMintQuantity()
                    });
            }
        }

        // Return an empty CollectionDetails struct if not found
        return
            CollectionDetails({
                collectionAddress: address(0),
                name: "",
                description: "",
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

    ///// -------------------------------------------------------------------------- ////

    /// --------------------------- Generate Fee --------------------------- ////
    function payGenerateFee() public payable returns (bool) {
        require(
            msg.value >= generateFee,
            "Payable: msg.value must be equal to amount"
        );
        return true;
    }

    ///// -------------------------------------------------------------------------- ////

    ///// ---------------------------- ADMIN ---------------------------------------- ////
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

    ///// -------------------------------------------------------------------------- ////

    //// ------------------------------ Users MINT ---------------------------------- ////
    function addUsersMints(address user, address collection) private {
        _usersMint[user].push(collection);
    }

    function getUserMints(address user) public view returns (address[] memory) {
        return _usersMint[user];
    }

    function getUserMintCount(address user) public view returns (uint256) {
        return _usersMint[user].length;
    }

    //// ------------------------------ Users Collecions ----------------------------------////

    function addUsersCollections(address user, address collection) private {
        _usersCollections[user].push(collection);
    }

    function getUserCollectionsCount(
        address user
    ) public view returns (uint256) {
        return _usersCollections[user].length;
    }

    function getUserCollections(
        address user
    ) public view returns (address[] memory) {
        return _usersCollections[user];
    }
}
