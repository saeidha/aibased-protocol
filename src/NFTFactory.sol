// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./NFTCollection.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AIBasedNFTFactory is Ownable {
    using Address for address payable;

    error InsufficientFee();
    error OnlyAdmin();
    error InvalidRecipient();
    error NoEtherToWithdraw();
    event ChangeGenerateFee(uint256 newFee);
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

    event EtherWithdrawn(address indexed recipient, uint256 amount);

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
        bool  isOwner;
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
        _usersCollections[msg.sender].push(address(collection));

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

    function createAndMint(
        string memory name,
        string memory description,
        string memory symbol,
        string memory imageURL
    ) external payable {
        uint256 maxTime = block.timestamp + 1 hours;
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
        _usersMint[msg.sender].push(collectionAddress);
        _usersCollections[msg.sender].push(collectionAddress);

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

    function mintNFT(address collectionAddress, address to, uint256 quantity) public payable {
        NFTCollection collection = NFTCollection(collectionAddress);
        bool mintedBefore = collection.hasMinted(to);
        collection.mintNFT{value: msg.value}(to, quantity);

        if (!mintedBefore) {
            _usersMint[to].push(collectionAddress);
        }
    }

    function getCollections() public view returns (address[] memory) {
        return deployedCollections;
    }

    function getMintPadCollections() public view returns (address[] memory) {
        return mintPadCollections;
    }

    function getAvailableCollectionsToMintDetails() external view returns (CollectionDetails[] memory) {
        CollectionDetails[] memory details = new CollectionDetails[](mintPadCollections.length);
        uint256 count = 0;
        for (uint256 i = 0; i < mintPadCollections.length; i++) {
            NFTCollection collection = NFTCollection(mintPadCollections[i]);
            if (!collection.canNotToShow()) {
                details[count++] = _getCollectionDetails(collection, mintPadCollections[i], true, false);
            }
        }
        return _trimDetails(details, count);
    }

    function getAvailableCollectionsToMintDetails(address sender) external view returns (CollectionDetails[] memory) {
        CollectionDetails[] memory details = new CollectionDetails[](mintPadCollections.length);
        uint256 count = 0;
        for (uint256 i = 0; i < mintPadCollections.length; i++) {
            NFTCollection collection = NFTCollection(mintPadCollections[i]);
            if (!collection.canNotToShow()) {
                CollectionDetails memory detail = _getCollectionDetails(collection, mintPadCollections[i], false, sender == collection.creatorAddress());
                detail.isDisable = collection.isDisabled(sender);
                details[count++] = detail;
            }
        }
        return _trimDetails(details, count);
    }

    function getUserCollectionsDetails(address sender) external view returns (CollectionDetails[] memory) {
        address[] memory usersCollections = _usersCollections[sender];
        CollectionDetails[] memory details = new CollectionDetails[](usersCollections.length);
        for (uint256 i = 0; i < usersCollections.length; i++) {
            NFTCollection collection = NFTCollection(usersCollections[i]);
            details[i] = _getCollectionDetails(collection, usersCollections[i], false, sender == collection.creatorAddress());
            details[i].isDisable = collection.isDisabled(sender);
        }
        return details;
    }

    function getCollectionDetailsByContractAddress(address contractAddress) external view returns (CollectionDetails memory) {
        for (uint256 i = 0; i < deployedCollections.length; i++) {
            if (deployedCollections[i] == contractAddress) {
                NFTCollection collection = NFTCollection(deployedCollections[i]);
                return _getCollectionDetails(collection, deployedCollections[i], true, false);
            }
        }
        return _emptyCollectionDetails();
    }

    function getCollectionDetailsByContractAddress(address contractAddress, address sender) external view returns (CollectionDetails memory) {
        for (uint256 i = 0; i < deployedCollections.length; i++) {
            if (deployedCollections[i] == contractAddress) {
                NFTCollection collection = NFTCollection(deployedCollections[i]);
                CollectionDetails memory detail = _getCollectionDetails(collection, deployedCollections[i], false, sender == collection.creatorAddress());
                detail.isDisable = collection.isDisabled(sender);
                return detail;
            }
        }
        return _emptyCollectionDetails();
    }

    function payGenerateFee() public payable {
        if (msg.value < generateFee) revert InsufficientFee();
    }

    function setGenerateFee(uint256 _newFee) public onlyOwner{
        if (msg.sender != owner()) revert OnlyAdmin();
        generateFee = _newFee;
        emit ChangeGenerateFee(_newFee);
    }

    function getFee() public view returns (uint256) {
        if (msg.sender != owner()) revert OnlyAdmin();
        return generateFee;
    }

    function withdraw() external onlyOwner {
        address payable recipient = payable(owner());
        if (recipient == address(0)) revert InvalidRecipient();
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoEtherToWithdraw();
        recipient.sendValue(balance);
        emit EtherWithdrawn(recipient, balance);
    }

    function getUserMints(address user) public view returns (address[] memory) {
        return _usersMint[user];
    }

    function getUserMintCount(address user) public view returns (uint256) {
        return _usersMint[user].length;
    }

    function getUserCollectionsCount(address user) public view returns (uint256) {
        return _usersCollections[user].length;
    }

    function getUserCollections(address user) public view returns (address[] memory) {
        return _usersCollections[user];
    }

    // Helper functions to reduce code duplication
    function _getCollectionDetails(NFTCollection collection, address collectionAddress, bool isDisable, bool isOwner) private view returns (CollectionDetails memory) {
        return CollectionDetails({
            collectionAddress: collectionAddress,
            name: collection.name(),
            description: collection.description(),
            tokenIdCounter: collection.totalSupply(),
            maxSupply: collection.maxSupply(),
            baseImageURI: collection.imageURL(),
            maxTime: collection.maxTime(),
            mintPerWallet: collection.mintPerWallet(),
            mintPrice: collection.mintPrice(),
            isDisable: isDisable,
            isUltimateMintTime: collection.isUltimateMintTime(),
            isUltimateMintQuantity: collection.isUltimateMintQuantity(),
            isOwner: isOwner
        });
    }

    function _trimDetails(CollectionDetails[] memory details, uint256 count) private pure returns (CollectionDetails[] memory) {
        CollectionDetails[] memory trimmed = new CollectionDetails[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmed[i] = details[i];
        }
        return trimmed;
    }

    function _emptyCollectionDetails() private pure returns (CollectionDetails memory) {
        return CollectionDetails({
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
            isUltimateMintQuantity: false,
            isOwner: false
        });
    }
}