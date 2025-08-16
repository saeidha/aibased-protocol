// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFactory {

    function getPlatformFee(uint256 _mintPrice) external view returns (uint256);
}

contract NFTCollection is ERC721, Ownable {
    using Strings for uint256;
    using Address for address payable;

    struct Counter {
        uint256 _value;
    }
    
    event TokenMinted(uint256 indexed tokenId, address indexed owner);
    event MaxSupplyUpdated(uint256 indexed newMaxSupply);
    event MaxTimeUpdated(uint256 indexed newMaxTime);
    event EtherWithdrawn(address indexed recipient, uint256 indexed amount);
    event WithdrawToCreator(address indexed creator, uint256 indexed amount);
    event BaseURIUpdated(string newURI);

    struct ContractConfig {
        string name;
        string description;
        string model;
        string style;
        string symbol;
        uint256 maxSupply;
        uint256 maxTime;
        string initialBaseURI;
        bool mintPerWallet;
        uint256 initialPrice;
        address admin;
        address initialOwner;
        address factoryAddress;
    }


    string public description;
    string public style;
    string public model;

    Counter private _tokenIdCounter;
    uint256 public maxSupply;
    string public _baseTokenURI;
    uint256 public maxTime;
    bool public immutable mintPerWallet;

    address public immutable factoryAddress;
    uint256 public immutable initialPrice;
    bool public isUltimateMintTime;
    bool public isUltimateMintQuantity;
    address public immutable creatorAddress;
    mapping(address => bool) public hasMinted;

    constructor(ContractConfig memory config)
     ERC721(config.name, config.symbol) 
     Ownable(config.admin) {

    require(config.maxTime >= block.timestamp + 60, "Max time should be end up next minutes");

    require(config.maxSupply >= 1, "Max Supply should be grather than 1");

        maxSupply = config.maxSupply;
        _baseTokenURI = config.initialBaseURI; 
        _tokenIdCounter._value = 0;
        maxTime =  config.maxTime;
        mintPerWallet = config.mintPerWallet;
        description = config.description;
        style = config.style;
        model = config.model;
        initialPrice = config.initialPrice;
        isUltimateMintTime = config.maxTime == type(uint256).max;
        isUltimateMintQuantity = config.maxSupply == type(uint256).max;
        creatorAddress = config.initialOwner;
        factoryAddress = config.factoryAddress;
    }

    function mint(address to, uint256 quantity) external payable {

        require(quantity > 0, "Quantity must be greater than zero");

        uint256 currentPlatformFee = IFactory(factoryAddress).getPlatformFee(initialPrice);
        uint256 ownerPayment = initialPrice * quantity;
        uint256 platformPayment = currentPlatformFee * quantity;

        // If the caller is the owner, set ownerPayment to 0
        if (to == creatorAddress) {
            ownerPayment = 0 ether;
        }

        // Total payment required
        uint256 totalPayment = ownerPayment + platformPayment;

        /// @dev Check if minting is free or paid 
        if (totalPayment != 0) {

            /// @dev Check if the amount of ETH sent is enough to mint the NFT
            require(msg.value >= totalPayment, "Insufficient ETH sent");
        }

        
        // Existing checks
        require(block.timestamp <= maxTime, "Minting period has ended");
        require(_tokenIdCounter._value + quantity <= maxSupply, "Exceeds max supply");
        

        // Wallet restriction
        if (mintPerWallet) {
            if (quantity > 1) {
                revert("Only one NFT per wallet");
            }
            require(!hasMinted[to], "Wallet already minted");
        }

        // Transfer ownerPayment to the owner of the collection
        if (ownerPayment > 0) {
            // Send payment to creator of the collection
            // Ensure the recipient is explicitly set to the creator of the collection
            address payable recipient = payable(creatorAddress);

            // Use OpenZeppelin's Address library to safely send Ether
            Address.sendValue(recipient, ownerPayment);

            emit WithdrawToCreator(creatorAddress, ownerPayment);
        }

        // Transfer platformPayment to the platform wallet
        if (platformPayment > 0) {
            // Send payment to the platform
            // Ensure the recipient is explicitly set to the platform
            address payable recipient = payable(owner());
            recipient.sendValue(platformPayment);

            emit EtherWithdrawn(recipient, platformPayment);
        }

        hasMinted[to] = true;
        // Batch increment the token ID counter
        uint256 startTokenId = _tokenIdCounter._value;
        uint256 endTokenId = startTokenId + quantity;
        _tokenIdCounter._value += quantity;

        // Mint tokens
        for (uint256 i = startTokenId + 1; i <= endTokenId; i++) {
            
            _safeMint(to, i);
        }
    }

    ////// -------- Base URI and Token URI Functions ------------ ////////
    // --- NEW: Overriding _baseURI to return our stored URI ---
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- NEW: Overriding tokenURI ---
    // Since all tokens have the same metadata, we can simply return the base URI.
    function tokenURI(uint256) public view override returns (string memory) {
        return _baseURI();
    }

    // --- NEW: Function to allow the owner to set the base URI from Pinata ---

    function setBaseURI(string memory _newURI) external onlyOwner {
        _baseTokenURI = _newURI;
        emit BaseURIUpdated(_newURI);
    }
    ////// ------------------------------------------------ ////////

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter._value;
    }

    function isDisabled(address sender) external view returns (bool) {
        return  canNotToShow() ||   // Supply reached
            (mintPerWallet && hasMinted[sender]);    // Wallet already minted (if restriction enabled)
    }

    function canNotToShow() public view returns (bool) {
        return block.timestamp > maxTime ||             // Time expired
            _tokenIdCounter._value >= maxSupply;   // Supply reached
    }

    /////-------- ADMIN ------------
    /// witdraw
 // Withdraw function to allow the owner to withdraw accumulated Ether
    function withdraw() external onlyOwner {
        address payable recipient = payable(owner());
        require(recipient != address(0), "Invalid recipient address");

        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");

        // Safely send Ether to the owner
        recipient.sendValue(balance);

        // Emit an event for logging
        emit EtherWithdrawn(recipient, balance);
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner{ 

        maxSupply = _newMaxSupply;
        isUltimateMintQuantity = _newMaxSupply == type(uint256).max;
        emit MaxSupplyUpdated(_newMaxSupply);
    }

    function setMaxTime(uint256 _newMaxTime) external onlyOwner{ 

        maxTime = _newMaxTime;
        isUltimateMintTime = _newMaxTime == type(uint256).max;
        emit MaxTimeUpdated(_newMaxTime);
    }

}