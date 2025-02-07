// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NFTCollection is ERC721, Ownable {
       using Strings for uint256;
    
    struct Counter {
        uint256 _value;
    }
    
    event TokenMinted(uint256 tokenId, address owner);

    Counter private _tokenIdCounter;
    uint256 public maxSupply;
    string public imageURL;
    uint256 public maxTime;
    bool public mintPerWallet;
    uint256 public mintPrice;
    string public description;
    uint256 private platformFee;
    address private immutable admin; 
    uint256 private initialPrice;
    bool public isUltimateMintTime;
    bool public isUltimateMintQuantity;

    mapping(address => bool) public hasMinted;

    constructor(
        string memory name,
        string memory _description,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _maxTime,
        string memory _imageURL,
        bool _mintPerWallet,
        uint256 _initialPrice,
        address _admin,
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {



require(_maxTime >= block.timestamp + 60, "Max time should be end up next minutes");

require(_maxSupply >= 1, "Max Supply should be grather than 1");

        maxSupply = _maxSupply;
        imageURL = _imageURL;
        _tokenIdCounter._value = 0;
        maxTime =  _maxTime;
        mintPerWallet = _mintPerWallet;
        description = _description;
        platformFee = calculatePlatformFee(_initialPrice) ;
        mintPrice = platformFee + _initialPrice;
        admin = _admin;
        initialPrice = _initialPrice;
        isUltimateMintTime = _maxTime == type(uint256).max;
        isUltimateMintQuantity = _maxSupply == type(uint256).max;
    }

    // function mint(address to, uint256 quantity) public onlyOwner {

    //     require(msg.sender == admin, "Only admin");
    // }
    function mintNFT(address to, uint256 quantity) public payable {

        require(quantity > 0, "Quantity must be greater than zero");

        uint256 ownerPayment = initialPrice * quantity;
        uint256 platformPayment = platformFee * quantity;

        // If the caller is the owner, set ownerPayment to 0
        if (to == owner()) {
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

        if (ownerPayment > 0) {
            // Send payment to owner
            payable(owner()).transfer(ownerPayment);
        }

        // Mint tokens
        for (uint256 i = 0; i < quantity; i++) {
            hasMinted[to] = true;
            _increment();
            _safeMint(to, _tokenIdCounter._value);
        }
    }


    function _increment() private {
        _tokenIdCounter._value += 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }


    function contractURI() external view returns (string memory) {
        string memory encodedName = string(abi.encode(name()));
        string memory imageURI = string(abi.encode(imageURL));
        string memory _description = string(abi.encode(description));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encode(
                        '{"name": "', encodedName, '",',
                        '"description":"', _description, '",',
                        '"image": "', imageURI, '"}'
                    )
                )
            )
        );

        return string(abi.encode(_baseURI(), json));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "Nonexistent token");

        string memory nameWithTokenId = string(
            abi.encode(name(), " #", Strings.toString(tokenId))
        );

        string memory imageURI = string(abi.encode(imageURL));
        string memory _description = string(abi.encode(description));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encode(
                        '{"name": "', nameWithTokenId, '",',
                        '"description":"', _description, '",',
                        '"image": "', imageURI, '"}'
                    )
                )
            )
        );

        return string(abi.encode(_baseURI(), json));
    }

    // Custom existence check using owner lookup
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter._value;
    }

    function calculatePlatformFee(uint256 mint_price) pure private returns (uint256) {

        if (mint_price > 0.002 ether) {

            return mint_price * 5 / 100;
        }else{

            return 0.0001 ether;
        }
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
    function withdraw() external {

        require(msg.sender == admin, "Only admin");
        payable(admin).transfer(address(this).balance);
    }

    function setMaxSupply(uint256 _newMaxSupply) public { 

        require(msg.sender == admin, "Only admin");
        maxSupply = _newMaxSupply;
        isUltimateMintQuantity = _newMaxSupply == type(uint256).max;
    }

    function setMaxTime(uint256 _newMaxTime) public { 

        require(msg.sender == admin, "Only admin");
        maxTime = _newMaxTime;
        isUltimateMintTime = _newMaxTime == type(uint256).max;
    }

    function changePlatformFee(uint256 _newPlatformFee) public { 

        require(msg.sender == admin, "Only admin");
        platformFee = _newPlatformFee;
    }

}