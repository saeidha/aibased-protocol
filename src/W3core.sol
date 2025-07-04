// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract W3core is ERC721, Ownable {
    using Strings for uint256;
    using Address for address payable;

    struct Counter {
        uint256 _value;
    }

    struct ContractConfig {
        string name;
        string description;
        string model;
        string style;
        string symbol;
        uint256 maxSupply;
        uint256 maxTime;
        string imageURL;
        bool mintPerWallet;
        uint256 initialPrice;
        address admin;
        address initialOwner;
    }

    string public description;
    string public style;
    string public model;

    Counter private _tokenIdCounter;
    uint256 public maxSupply;
    string public imageURL;
    uint256 public maxTime;
    bool public immutable mintPerWallet;
    uint256 public mintPrice;

    uint256 private platformFee;
    uint256 private immutable initialPrice;
    bool public isUltimateMintTime;
    bool public isUltimateMintQuantity;
    address public immutable creatorAddress;

    mapping(address => bool) public hasMinted;
    bytes32 public discountMerkleRoot;

    event TokenMinted(uint256 indexed tokenId, address indexed owner);
    event MaxSupplyUpdated(uint256 indexed newMaxSupply);
    event MaxTimeUpdated(uint256 indexed newMaxTime);
    event ChangePlatformFee(uint256 indexed newFee);
    event EtherWithdrawn(address indexed recipient, uint256 indexed amount);
    event WithdrawToCreator(address indexed creator, uint256 indexed amount);

    constructor(ContractConfig memory config) ERC721(config.name, config.symbol) Ownable(config.admin) {
        require(config.maxTime >= block.timestamp + 60, "Max time should be in future");
        require(config.maxSupply >= 1, "Max Supply should be greater than 0");

        maxSupply = config.maxSupply;
        imageURL = config.imageURL;
        _tokenIdCounter._value = 0;
        maxTime = config.maxTime;
        mintPerWallet = config.mintPerWallet;
        description = config.description;
        style = config.style;
        model = config.model;
        platformFee = calculatePlatformFee(config.initialPrice);
        mintPrice = config.initialPrice + platformFee;
        initialPrice = config.initialPrice;
        isUltimateMintTime = config.maxTime == type(uint256).max;
        isUltimateMintQuantity = config.maxSupply == type(uint256).max;
        creatorAddress = config.initialOwner;
    }

    function setDiscountMerkleRoot(bytes32 _root) external onlyOwner {
        discountMerkleRoot = _root;
    }

    function _getDiscount(address user, bytes32[] calldata proof) internal view returns (uint8) {

        uint8[4] memory possibleDiscounts = [100, 50, 10 ,25];

        for (uint256 i = 0; i < possibleDiscounts.length; i++) {
            uint8 d = possibleDiscounts[i];
            bytes32 leaf = keccak256(abi.encodePacked(user, d));
            if (MerkleProof.verify(proof, discountMerkleRoot, leaf)) {
                return d;
            }
        }

        return 0; // Not in whitelist = 0% discount
    }

    function mint(address to, uint256 quantity, bytes32[] calldata proof) external payable {

        require(quantity > 0, "Quantity must be greater than zero");

        uint8 discount = _getDiscount(to, proof);

        uint256 userUnitPrice = initialPrice * (100 - discount) / 100;
        uint256 totalUserPay = userUnitPrice * quantity;
        uint256 totalPlatformPay = platformFee * quantity;
        uint256 totalPayment = totalUserPay + totalPlatformPay;

        if (to == creatorAddress) totalUserPay = 0;

        require(msg.value >= totalPayment, "Insufficient ETH sent");
        require(block.timestamp <= maxTime, "Minting period has ended");
        require(_tokenIdCounter._value + quantity <= maxSupply, "Exceeds max supply");

        if (mintPerWallet) {
            require(quantity == 1, "Only one NFT per wallet");
            require(!hasMinted[to], "Wallet already minted");
        }

        if (totalUserPay > 0) {
            payable(creatorAddress).sendValue(totalUserPay);
            emit WithdrawToCreator(creatorAddress, totalUserPay);
        }

        if (totalPlatformPay > 0) {
            payable(owner()).sendValue(totalPlatformPay);
            emit EtherWithdrawn(owner(), totalPlatformPay);
        }

        hasMinted[to] = true;

        for (uint256 i = 1; i <= quantity; i++) {
            _tokenIdCounter._value++;
            _safeMint(to, _tokenIdCounter._value);
        }
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter._value;
    }

    function calculatePlatformFee(uint256 mint_price) pure private returns (uint256) {
        return mint_price > 0.002 ether ? (mint_price * 5 / 100) : 0.0001 ether;
    }

    function isDisabled(address sender) external view returns (bool) {
        return canNotToShow() || (mintPerWallet && hasMinted[sender]);
    }

    function canNotToShow() public view returns (bool) {
        return block.timestamp > maxTime || _tokenIdCounter._value >= maxSupply;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
        isUltimateMintQuantity = _newMaxSupply == type(uint256).max;
        emit MaxSupplyUpdated(_newMaxSupply);
    }

    function setMaxTime(uint256 _newMaxTime) external onlyOwner {
        maxTime = _newMaxTime;
        isUltimateMintTime = _newMaxTime == type(uint256).max;
        emit MaxTimeUpdated(_newMaxTime);
    }

    function changePlatformFee(uint256 _newPlatformFee) external onlyOwner {
        platformFee = _newPlatformFee;
        mintPrice = platformFee + initialPrice;
        emit ChangePlatformFee(_newPlatformFee);
    }

    function mintPriceForUser(address user, bytes32[] calldata proof) external view returns (uint256) {

        uint8 discount = _getDiscount(user, proof);
        return user == creatorAddress ? platformFee : (initialPrice * (100 - discount) / 100) + platformFee;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function contractURI() external view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"', name(), '",',
                    '"description":"', description, '",',
                    '"style":"', style, '",',
                    '"model":"', model, '",',
                    '"image":"', imageURL, '"}'
                )
            )
        );
        return string.concat(_baseURI(), json);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Nonexistent token");

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"', name(), ' #', tokenId.toString(), '",',
                    '"description":"', description, '",',
                    '"style":"', style, '",',
                    '"model":"', model, '",',
                    '"image":"', imageURL, '"}'
                )
            )
        );
        return string.concat(_baseURI(), json);
    }

    function withdraw() external onlyOwner {
        address payable recipient = payable(owner());
        require(recipient != address(0), "Invalid recipient address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        recipient.sendValue(balance);
        emit EtherWithdrawn(recipient, balance);
    }
}
