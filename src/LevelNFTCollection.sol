// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title LevelNFTCollection
 * @dev An NFT collection for "The Core Stack".
 * Metadata is stored off-chain on IPFS and the contract constructs the URI
 * based on the token's level.
 */
contract LevelNFTCollection is ERC721, Ownable {
    using Strings for uint256;

    // --- FIX ---
    // Renamed the state variable to avoid conflict with the inherited _baseURI() function.
    string private _tokenBaseURI;

    uint256 private _nextTokenId;
    address public factoryAddress;

    // Mapping from token ID to its level
    mapping(uint256 => uint256) public tokenLevels;

    event FactoryAddressSet(address indexed newFactoryAddress);
    event BaseURISet(string newBaseURI);

    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "Caller is not the authorized factory");
        _;
    }

    // Pass the factory address and the IPFS metadata URI during deployment.
    constructor(
        address initialFactory,
        string memory initialBaseURI
    ) ERC721("The Core Stack", "CORE") Ownable(msg.sender) {
        factoryAddress = initialFactory;
        // --- FIX ---
        // Set the newly named state variable.
        _tokenBaseURI = initialBaseURI;
    }
    
    /**
     * @dev Returns the base URI for all token IDs by overriding the standard function.
     */
    function _baseURI() internal view override returns (string memory) {
        // --- FIX ---
        // Return the value from our correctly named state variable.
        return _tokenBaseURI;
    }

    /**
     * @dev Constructs and returns the metadata URI for a given token ID.
     * It fetches the token's level and appends it to the base URI.
     * Example: ipfs://METADATA_CID/5.json
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        uint256 level = tokenLevels[tokenId];
        
        // Concatenate the base URI, the level, and the ".json" suffix.
        return string(abi.encodePacked(_baseURI(), level.toString(), ".json"));
    }

    /**
     * @dev Allows the contract owner to update the base URI for metadata.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        
        // Update the newly named state variable.
        _tokenBaseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }
    
    // ... The rest of the functions (mint, setFactoryAddress, etc.) remain the same ...
    function mint(address to, uint256 level) external onlyFactory returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        tokenLevels[tokenId] = level;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function setFactoryAddress(address _newFactoryAddress) external onlyOwner {
        require(_newFactoryAddress != address(0), "Cannot be zero address");
        factoryAddress = _newFactoryAddress;
        emit FactoryAddressSet(_newFactoryAddress);
    }
}