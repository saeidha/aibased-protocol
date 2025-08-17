// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title W3PASS NFT
 * @dev An exclusive NFT with a discount system managed by a Merkle Tree.
 * Minting is restricted to a designated factory contract.
 */
contract W3PASS is ERC721, Ownable, ReentrancyGuard {
    // --- State Variables ---

    // The address of the AIBasedNFTFactory, the only contract allowed to mint.
    address public factoryAddress;

    // The root of the Merkle Tree containing whitelisted addresses and their discount tiers.
    bytes32 public merkleRoot;

    uint256 public basePrice;

    // Counter for the next token ID.
    uint256 private _nextTokenId;

    string private _baseTokenURI;

    // Mapping to ensure each wallet can only mint once.
    mapping(address => bool) private _hasMinted;

    // --- Events ---

    event MerkleRootUpdated(bytes32 indexed newRoot);
    event PassMinted(address indexed to, uint256 indexed tokenId, uint256 pricePaid);
    event BasePriceUpdated(uint256 indexed newPrice);
    event BaseURIUpdated(string newURI);
    // --- Errors ---

    error AlreadyMinted();
    error InvalidProof();
    error InsufficientPayment();
    error NotFactory();
    error ProofRequiredForDiscount();
    error NonTransferable();
    error TransferFailed();


    // --- Constructor ---
constructor(
        address _factoryAddress,
        bytes32 _initialMerkleRoot,
        uint256 _initialPrice,
        string memory _initialBaseURI
    ) ERC721("W3PASS", "W3P") Ownable(msg.sender) {
        require(_factoryAddress != address(0), "Factory address cannot be zero");
        factoryAddress = _factoryAddress;
        merkleRoot = _initialMerkleRoot;
        basePrice = _initialPrice; // Set initial price
        _baseTokenURI = _initialBaseURI; // Set initial URI
    }

    // --- Core Functions ---

    /**
     * @dev Mints a new W3PASS NFT. Can only be called by the factory contract.
     * Verifies the user's discount eligibility using a Merkle proof.
     * @param _to The address that will receive the NFT.
     * @param _discountTier A number representing the discount level (e.g., 0=no discount, 1=20% off, etc.).
     * @param _merkleProof The proof provided by the user to validate their inclusion in the Merkle Tree.
     */
    function mint(
        address _to,
        uint256 _discountTier,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        if (msg.sender != factoryAddress) revert NotFactory();
        if (_hasMinted[_to]) revert AlreadyMinted();

        uint256 finalPrice;

        // --- NEW DUAL-PATH LOGIC ---
        if (_discountTier > 0) {
            // --- PATH 1: Discounted Mint ---
            // A proof is mandatory for any discount tier greater than 0.
            if (_merkleProof.length == 0) revert ProofRequiredForDiscount();

            // Construct and verify the leaf for the discounted user.
            bytes32 leaf = keccak256(abi.encodePacked(_to, _discountTier));
            if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
                revert InvalidProof();
            }
            finalPrice = getPrice(_discountTier);

        } else {
            // --- PATH 2: Public Mint (No Discount) ---
            // For tier 0, no proof is needed. The price is the base price.
            finalPrice = basePrice;
        }

        if (msg.value < finalPrice) revert InsufficientPayment();

        // Transfer the revenue to the owner's address.
        if (finalPrice > 0) {
            (bool success, ) = payable(owner()).call{value: finalPrice}("");
            if (!success) {
                revert TransferFailed();
            }
        }
        
        // Refund any excess payment to the user who initiated the transaction.
        if (msg.value > finalPrice) {
            (bool success, ) = payable(_to).call{value: msg.value - finalPrice}("");
            if (!success) {
                revert TransferFailed();
            }
        }


        _hasMinted[_to] = true;
        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);

        emit PassMinted(_to, tokenId, finalPrice);
    }

    // --- FINAL CORRECTED V5 OVERRIDE: Make tokens non-transferable ---
    /*** @dev In OpenZeppelin v5, the `_update` function is the main hook for all
     * token movements, including mint, transfer, and burn.
     * We override it to implement our non-transferable (soulbound) logic.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        // Before the state change, get the current owner. This is the 'from' address.
        address from = _ownerOf(tokenId);

        // Allow minting (from == address(0)) but block all other transfers.
        if (from != address(0)) {
            revert NonTransferable();
        }

        // Call the parent's _update function to execute the mint.
        return super._update(to, tokenId, auth);
    }




    // --- View Functions ---

    /**
     * @dev Calculates the price for a given discount tier.
     * Tier 0: No discount (base price)
     * Tier 1: 25% discount
     * Tier 2: 50% discount
     * Tier 3: 100% discount (free)
     */
    function getPrice(uint256 _discountTier) public view returns (uint256) {
        if (_discountTier == 1) {
            return basePrice * 75 / 100; // 25% off
        }
        if (_discountTier == 2) {
            return basePrice * 50 / 100; // 50% off
        }
        if (_discountTier >= 3) {
            return 0; // 100% off
        }
        return basePrice; // Default: No discount
    }

    // --- NEW: Overriding _baseURI to return our stored URI ---
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- NEW: Overriding tokenURI ---
    // Since all W3PASS tokens have the same metadata, we can simply return the base URI.
    function tokenURI(uint256) public view override returns (string memory) {
        return _baseURI();
    }

    // --- Admin Functions ---

    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(_newRoot);
    }

    // --- NEW: Function to allow the owner to update the base price ---
    function setBasePrice(uint256 _newPrice) external onlyOwner {
        basePrice = _newPrice;
        emit BasePriceUpdated(_newPrice);
    }

    // --- NEW: Function to allow the owner to set the base URI from Pinata ---
    function setBaseURI(string memory _newURI) external onlyOwner {
        _baseTokenURI = _newURI;
        emit BaseURIUpdated(_newURI);
    }

    function setFactoryAddress(address _newFactory) external onlyOwner {
        require(_newFactory != address(0), "Factory address cannot be zero");
        factoryAddress = _newFactory;
    }
}