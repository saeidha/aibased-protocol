// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAIBasedNFTFactory {
    function getCollections() external view returns (address[] memory);
}

interface INFTCollection {
    function owner() external view returns (address);
    function withdraw() external;
}

contract WithdrawCollections {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function run() external {
        require(msg.sender == owner, "Not owner");

        // Factory address
        address factoryAddress = 0x8e49aD54352E8658a7EBb8e6B22A33299832F27D;
        IAIBasedNFTFactory factory = IAIBasedNFTFactory(factoryAddress);

        // Get all collections
        address[] memory collections = factory.getCollections();

        // Process each collection
        for (uint256 i = 0; i < collections.length; i++) {
            address collectionAddress = collections[i];
            INFTCollection collection = INFTCollection(collectionAddress);
            
            // Check if we are the owner
            if (collection.owner() == owner) {
                uint256 balance = address(collection).balance;
                if (balance > 0) {
                    collection.withdraw();
                }
            }
        }
    }
} 