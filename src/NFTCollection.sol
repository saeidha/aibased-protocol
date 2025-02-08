// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTCollection is ERC721, Ownable {
    using Strings for uint256;
    using Address for address payable;

    struct Counter {
        uint256 _value;
    }
    
    event TokenMinted(uint256 tokenId, address owner);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event MaxTimeUpdated(uint256 newMaxTime);
    event ChangePlatformFee(uint256 newFee);
    event EtherWithdrawn(address indexed recipient, uint256 amount);
    event WithdrawToCreator(address creator, uint256 amount);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

    Counter private _tokenIdCounter;
    uint256 public maxSupply;
    string public imageURL;
    uint256 public maxTime;
    bool public immutable mintPerWallet;
    uint256 public immutable mintPrice;
    string public description;
    uint256 private platformFee;
    uint256 private immutable initialPrice;
    bool public isUltimateMintTime;
    bool public isUltimateMintQuantity;
    address private immutable creatorAddress;
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
    ) ERC721(name, symbol) Ownable(_admin) {



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
        initialPrice = _initialPrice;
        isUltimateMintTime = _maxTime == type(uint256).max;
        isUltimateMintQuantity = _maxSupply == type(uint256).max;
        creatorAddress = initialOwner;
        
    }

    // function mint(address to, uint256 quantity) public onlyOwner {

    //     require(msg.sender == admin, "Only admin");
    // }
    function mintNFT(address to, uint256 quantity) external payable {

        require(quantity > 0, "Quantity must be greater than zero");

        uint256 ownerPayment = initialPrice * quantity;
        uint256 platformPayment = platformFee * quantity;

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
    // Directly use the contract name
    string memory encodedName = name();

    // Directly use the image URL
    string memory imageURI = imageURL;

    // Directly use the description
    string memory _description = description;

    // Build the JSON metadata
    string memory json = Base64.encode(
        bytes(
            string.concat(
                '{"name":"', encodedName, '",',
                '"description":"', _description, '",',
                '"image":"', imageURI, '"}'
            )
        )
    );

    // Return the full metadata URI
    return string.concat(_baseURI(), json);
}


function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(exists(tokenId), "Nonexistent token");

    // Construct the name with the token ID
    string memory nameWithTokenId = string.concat(name(), " #", Strings.toString(tokenId));

    // Construct the image URI
    string memory imageURI = imageURL; // Assuming imageURL is already a properly formatted string

    // Construct the description
    string memory _description = description; // Assuming description is already a properly formatted string

    // Construct the JSON metadata
    string memory json = Base64.encode(
        bytes(
            string.concat(
                '{"name":"', nameWithTokenId, '",',
                '"description":"', _description, '",',
                '"image":"', imageURI, '"}'
            )
        )
    );

    // Return the full token URI
    return string.concat(_baseURI(), json);
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

    function changePlatformFee(uint256 _newPlatformFee) external onlyOwner{ 

        platformFee = _newPlatformFee;
        emit ChangePlatformFee(_newPlatformFee);
    }

}