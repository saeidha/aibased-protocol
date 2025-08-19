// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface AIBasedNFTFactory {
    
}

contract AIBasedBadge is Ownable {
    address[] public factories;

    constructor(address[] memory _factories) Ownable(msg.sender) {
        factories = _factories;
    }

    function addFactory(address _factory) external onlyOwner {
        factories.push(_factory);
    }

    function removeFactory(address _factory) external onlyOwner {
        for (uint256 i = 0; i < factories.length; i++) {
            if (factories[i] == _factory) {
                factories[i] = factories[factories.length - 1];
                factories.pop();
                break;
            }
        }
    }

    function getUserMintCount(address user) external view returns (uint256) {
        uint256 totalMints = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            totalMints += AIBasedNFTFactory(factories[i]).getUserMintCount(user);
        }
        return totalMints;
    }

    function getUserCollectionsCount(address user) external view returns (uint256) {
        uint256 totalCollections = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            totalCollections += AIBasedNFTFactory(factories[i]).getUserCollectionsCount(user);
        }
        return totalCollections;
    }

    function getUserPayGenerateFeeCount(address user) external view returns (uint256) {
        uint256 totalFeeCount = 0;
        for (uint256 i = 0; i < factories.length; i++) {
            totalFeeCount += AIBasedNFTFactory(factories[i]).getUserPayGenerateFeeCount(user);
        }
        return totalFeeCount;
    }
}
