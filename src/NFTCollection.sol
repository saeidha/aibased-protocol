// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTCollection is ERC721, Ownable {
       using Strings for uint256;
    
    struct Counter {
        uint256 _value;
    }
    
    event TokenMinted(uint256 tokenId, address owner);

    Counter private _tokenIdCounter;
    uint256 public maxSupply;
    string public baseTokenURI;
    bool public revealed;
    string public unrevealedURI;
    uint256 public maxTime;
    bool public mintPerWallet;
    mapping(address => bool) public hasMinted;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _maxTime,
        string memory _baseTokenURI,
        bool _mintPerWallet,
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {

        maxSupply = _maxSupply == 0 ? type(uint256).max : _maxSupply;
        baseTokenURI = _baseTokenURI;
        _tokenIdCounter._value = 0;
        revealed = true;
        maxTime =  block.timestamp + (_maxTime == 0 ? 1 minutes : (_maxTime * 1 minutes));
        mintPerWallet = _mintPerWallet;
    }

    function mint(address to, uint256 quantity) public onlyOwner {
        require(block.timestamp <= maxTime, "Minting period has ended");
        require(
            _tokenIdCounter._value + quantity <= maxSupply,
            "Exceeds max supply"
        );
        if (mintPerWallet) {
            if (quantity > 1) {
                revert("Only one NFT per wallet");
            }
            require(!hasMinted[to], "Wallet already minted");
            hasMinted[to] = true;
        }

        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter._value++;  // Access struct value
            _safeMint(to, _tokenIdCounter._value);
            emit TokenMinted(_tokenIdCounter._value, to);  // Fix here
        }
    }


    function _increment() internal {
        _tokenIdCounter._value += 1;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }
    
    function reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "Nonexistent token");
        
        if (!revealed) {
            return unrevealedURI;
        }
        
        return string(abi.encodePacked(
            baseTokenURI
        ));
    }

    // Custom existence check using owner lookup
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter._value;
    }
}