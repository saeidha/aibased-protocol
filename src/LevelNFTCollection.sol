// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title LevelNFTCollection
 * @dev An NFT collection where each token has a "Level" trait.
 * Minting is restricted to a designated factory contract.
 * The metadata (including the level trait) is generated on-chain.
 */
contract LevelNFTCollection is ERC721, Ownable {
    using Strings for uint256;

    uint256 private _nextTokenId;
    address public factoryAddress;

    // Mapping from token ID to its level
    mapping(uint256 => uint256) public tokenLevels;

    // Event to announce when the factory address is changed
    event FactoryAddressSet(address indexed newFactoryAddress);

    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "Caller is not the authorized factory");
        _;
    }

    constructor(address initialFactory) ERC721("Level NFT", "LVLNFT") Ownable(msg.sender) {
        factoryAddress = initialFactory;
    }

    /**
     * @dev The core minting function, callable only by the factory.
     * It creates a new NFT, assigns it to the 'to' address, and stores its level.
     * @param to The address that will receive the NFT.
     * @param level The level to be assigned to the new NFT.
     * @return The ID of the newly minted token.
     */
    function mint(address to, uint256 level) external onlyFactory returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        tokenLevels[tokenId] = level;
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    /**
     * @dev Generates the token URI on-the-fly, including attributes.
     * Returns a Base64 encoded JSON string, compliant with OpenSea standards.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        uint256 level = tokenLevels[tokenId];
        
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "Level NFT #', tokenId.toString(), '",',
                    '"description": "A unique, level-based NFT granted by the AIBased Factory.",',
                    '"image": "ipfs://bafybeifx7yeb55armcsxwwitkymga5xf53dxiarykms3ygq42o53uc4bqy/nft-image.png",', // A placeholder image
                    '"attributes": [',
                        '{ "trait_type": "Level", "value": ', level.toString(), ' }',
                    ']}'
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev Allows the contract owner to update the factory address if needed.
     */
    function setFactoryAddress(address _newFactoryAddress) external onlyOwner {
        require(_newFactoryAddress != address(0), "Cannot be zero address");
        factoryAddress = _newFactoryAddress;
        emit FactoryAddressSet(_newFactoryAddress);
    }
}