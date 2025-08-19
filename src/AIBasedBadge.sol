// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface AIBasedNFTFactory {
    function getUserMintCount(address user) external view returns (uint256);
    function getUserCollectionsCount(address user) external view returns (uint256);
    function getUserPayGenerateFeeCount(address user) external view returns (uint256);
}

}
