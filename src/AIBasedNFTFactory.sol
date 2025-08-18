// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./NFTCollection.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface ILevelNFTCollection {
    function mint(address to, uint256 level) external returns (uint256);
}

interface IW3PASS {
    function mint(address _to, uint256 _discountTier, bytes32[] calldata _merkleProof) external payable;
}

contract AIBasedNFTFactory is Ownable {
    using Address for address payable;
    using ECDSA for bytes32;

    error InsufficientFee();
    error OnlyAdmin();
    error InvalidRecipient();
    error NoEtherToWithdraw();

    address[] public deployedCollections;
    address[] public mintPadCollections;

    mapping(address => address[]) private _usersCollections;
    mapping(address => address[]) private _usersMint;
    mapping(address => uint256) private _userGenerationFeeCount;

    uint256 private generateFee = 0 ether;

    /*** @dev The address authorized to sign minting requests for Level NFTs.
     * This is set by the factory owner and is used to verify signatures.*/
    address public authorizer;

    /*** @dev The address of the deployed LevelNFTCollection contract.
     * The factory will call the mint function on this contract.*/
    address public levelNFTCollection;

    /*** @dev Tracks which levels each wallet has already minted.
     * `mapping(walletAddress => mapping(level => hasMinted))`
     */
    mapping(address => mapping(uint256 => bool)) public hasMintedLevel;


    /*** @dev To prevent replay attacks, each signature can only be used once.
     * We store the hash of the used signatures.*/
    mapping(bytes32 => bool) public usedSignatures;

    // Add this new mapping
    mapping(string => uint256) public modelGenerationFee;


    // The address of the deployed W3PASS contract.
    address public w3PassAddress;

    uint256 public basePlatformFee;
    uint256 public maxBasePlatformFee;
    uint256 public percentagePlatformFee;

    constructor() Ownable(msg.sender) {

        modelGenerationFee["v1"] = 0.000003 ether;
        modelGenerationFee["v2"] = 0.000003 ether;
        basePlatformFee = 0.000003 ether;
        maxBasePlatformFee = 0.002 ether;
        percentagePlatformFee = 5;
    }


    event CollectionCreated(
        address indexed collection,
        string indexed name,
        string indexed description,
        string model,
        string style,
        string symbol,
        uint256 maxSupply,
        uint256 maxTime,
        string initialBaseURI,
        bool mintPerWallet,
        uint256 mintPrice,
        address owner
    );
    event ChangeGenerateFee(uint256 indexed newFee);
    event PayGenerateFee(address indexed payer, uint256 indexed amount);
    event EtherWithdrawn(address indexed recipient, uint256 indexed amount);
    event NFTMinted(address indexed collectionAddress, address indexed to, uint256 indexed quantity);

    /*** @dev Emitted when the authorizer address is changed by the owner.*/
    event AuthorizerSet(address indexed newAuthorizer);
    /*** @dev Emitted when the Level NFT collection address is set by the owner.*/
    event LevelNFTCollectionSet(address indexed collectionAddress);
    /*** @dev Emitted when a user successfully mints a Level NFT through the factory. */
    event LevelNFTMinted(address indexed collectionAddress, address indexed minter,
     uint256 indexed level, uint256 tokenId);
     // Add this new event
    event ModelFeeSet(string indexed model, uint256 indexed newFee);
    // Update this error
    error OnlyAdminOrAuthorizer();

     /*** @dev Emitted when the W3PASS contract address is set.*/
    event W3PassAddressSet(address indexed w3PassAddress);
    /*** @dev Emitted when a user successfully mints a W3PASS through the factory.*/
    event W3PassMinted(address indexed minter);

    event BasePlatformFeeSet(uint256 indexed newFee);
    event MaxBasePlatformFeeSet(uint256 indexed maxNewFee);
    event PercentagePlatformFeeSet(uint256 indexed newPercentage);

    struct CollectionDetails {
        address collectionAddress;
        string name;
        string description;
        uint256 tokenIdCounter;
        uint256 maxSupply;
        string initialBaseURI;
        uint256 maxTime;
        bool mintPerWallet;
        uint256 mintPrice;
        uint256 actualPrice;
        bool isDisable;
        bool isUltimateMintTime;
        bool isUltimateMintQuantity;
    }
    
    function createCollection(
        string memory name,
        string memory description,
        string memory model,
        string memory style,
        string memory symbol,
        string memory initialBaseURI,
        uint256 maxSupply,
        uint256 maxTime,
        bool mintPerWallet,
        uint256 mintPrice,
        bool isUltimateMintTime,
        bool isUltimateMintQuantity
    ) external returns (address) {

        NFTCollection.ContractConfig memory config = NFTCollection.ContractConfig({
            name: name,
            description: description,
            model: model,
            style: style,  
            symbol: symbol,
            maxSupply: isUltimateMintQuantity ? type(uint256).max : maxSupply,
            maxTime: isUltimateMintTime ? type(uint256).max : maxTime,
            initialBaseURI: initialBaseURI,
            mintPerWallet: mintPerWallet,
            initialPrice: mintPrice,
            admin: owner(),
            initialOwner: msg.sender,
            factoryAddress: address(this)
        });

        NFTCollection collection = new NFTCollection(config);

        deployedCollections.push(address(collection));
        mintPadCollections.push(address(collection));
        _usersCollections[msg.sender].push(address(collection));

        emit CollectionCreated(
            address(collection),
            name,
            description,
            config.model,
            config.style,
            config.symbol,
            config.maxSupply,
            config.maxTime,
            config.initialBaseURI,
            config.mintPerWallet,
            config.initialPrice,
            config.initialOwner
        );
        return address(collection);
    }

    function createAndMint(
        string memory name,
        string memory description,
        string memory model,
        string memory style,
        string memory symbol,
        string memory initialBaseURI
    ) external payable {

        // Step 1: Validate the minting fee.
        require(msg.value == basePlatformFee, "Invalid minting fee sent");

        uint256 maxTime = block.timestamp + 1 hours;
        uint256 maxSupply = 1;

        NFTCollection.ContractConfig memory config = NFTCollection.ContractConfig({
            name: name,
            description: description,
            model: model,
            style: style,
            symbol: symbol,
            maxSupply: maxSupply,
            maxTime: maxTime,
            initialBaseURI: initialBaseURI,
            mintPerWallet: true,
            initialPrice: 0,
            admin: owner(),
            initialOwner: msg.sender,
            factoryAddress: address(this)
        });
        NFTCollection collection = new NFTCollection(config);

        address collectionAddress = address(collection);
        deployedCollections.push(collectionAddress);
        _usersMint[msg.sender].push(collectionAddress);
        _usersCollections[msg.sender].push(collectionAddress);

        emit CollectionCreated(
            collectionAddress,
            name,
            description,
            model,
            style,
            symbol,
            maxSupply,
            maxTime,
            initialBaseURI,
            true,
            0,
            msg.sender
        );


        collection.mint{value: msg.value}(msg.sender, 1);

        emit NFTMinted(collectionAddress, msg.sender, 1);
    }

    function mintNFT(address collectionAddress, address to, uint256 quantity) external payable {
        NFTCollection collection = NFTCollection(collectionAddress);

        uint256 initialPrice = collection.initialPrice();

        uint256 currentPlatformFee = getPlatformFee(initialPrice);
        uint256 ownerPayment = initialPrice * quantity;
        uint256 platformPayment = currentPlatformFee * quantity;
        uint256 requiredPrice = ownerPayment + platformPayment;

        // Step 2: Check if the sent ETH is enough.
        require(msg.value == requiredPrice, "Invalid ETH amount sent");

        bool mintedBefore = collection.hasMinted(to);
        

        collection.mint{value: msg.value}(to, quantity);

        if (!mintedBefore) {
            _usersMint[to].push(collectionAddress);
        }

        emit NFTMinted(collectionAddress, to, quantity);
    }

    function withdraw() external onlyOwner {
        address payable recipient = payable(owner());
        if (recipient == address(0)) revert InvalidRecipient();
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoEtherToWithdraw();
        recipient.sendValue(balance);
        emit EtherWithdrawn(recipient, balance);
    }

////// ----------------- GENERATE AND MODRL SETTINGS ------------------///////
    /*** @dev Allows a user to pay the generation fee for a specific model.
     * @param model The model identifier (e.g., "v1", "v2").*/
    function payGenerateFee(string calldata model) external payable {

        uint256 requiredFee = modelGenerationFee[model];
        require(msg.value == requiredFee, "Invalid ETH amount sent");
        _userGenerationFeeCount[msg.sender] += 1;
        emit PayGenerateFee(msg.sender, msg.value);
    }

    /*** @dev Adds a new model and sets its initial generation fee.
    * Can only be called by the contract owner.
    * @param model The new model identifier.
    * @param _initialFee The initial fee for the new model.*/
    function addModel(string calldata model, uint256 _initialFee) external onlyOwner {
        require(modelGenerationFee[model] == 0, "Model already exists");
        modelGenerationFee[model] = _initialFee;
        emit ModelFeeSet(model, _initialFee);
    }

    /*** @dev Sets the generation fee for a specific model.
    * Can only be called by the contract owner or the authorizer.
    * @param model The model identifier (e.g., "v1", "v2").
    * @param _newFee The new fee in wei.*/
    function setGenerationModelFee(string calldata model, uint256 _newFee) external {
        if (msg.sender != owner() && msg.sender != authorizer) revert OnlyAdminOrAuthorizer();
        modelGenerationFee[model] = _newFee;
        emit ModelFeeSet(model, _newFee);
    }

    /*** @dev Returns the generation fee for a specific model.
     * @param model The model identifier (e.g., "v1", "v2").
     * @return The fee in wei for the given model.*/
    function getGenerationFee(string calldata model) external view returns (uint256) {
        return modelGenerationFee[model];
    }

///// -------------------------------------------------------------////////

////// ----------------- PLATFORM FEE SETTINGS ------------------///////
    // Add this new function
    function setBasePlatformFee(uint256 _newFee) external {
        if (msg.sender != owner() && msg.sender != authorizer) revert OnlyAdminOrAuthorizer();
        basePlatformFee = _newFee;
        emit BasePlatformFeeSet(_newFee);
    }

    // Add this new set maxBasePlatformFee function
    function setMaxBasePlatformFee(uint256 _newFee) external {
        if (msg.sender != owner() && msg.sender != authorizer) revert OnlyAdminOrAuthorizer();
        maxBasePlatformFee = _newFee;
        emit MaxBasePlatformFeeSet(_newFee);
    }

        // Add this new set Percentage PlatformFee function
    function setPercentageBasePlatformFee(uint256 _newFee) external {
        if (msg.sender != owner() && msg.sender != authorizer) revert OnlyAdminOrAuthorizer();
        percentagePlatformFee = _newFee;
        emit PercentagePlatformFeeSet(_newFee);
    }

    /*** @dev Calculates the platform fee based on a collection's mint price.
    * @param _mintPrice The initial mint price of an NFT in a collection.
    * @return The calculated platform fee.*/
    function getPlatformFee(uint256 _mintPrice) public view returns (uint256) {
        if (_mintPrice > maxBasePlatformFee) {
            // Return percentagePlatformFee% of the mint price
            return (_mintPrice * percentagePlatformFee) / 100;
        } else {
            // Return the base fee
            return basePlatformFee;
        }
    }

///// -------------------------------------------------------------////////


    function getCollections() external view returns (address[] memory) {
        return deployedCollections;
    }

    function getMintPadCollections() external view returns (address[] memory) {
        return mintPadCollections;
    }

    function getUserCollection(address user) external view returns (address[] memory) {

        return _usersCollections[user];
    }

    function getMintCollection(address user) external view returns (address[] memory) {

        return _usersMint[user];
    }

    /**
     * @dev Sets the address of the authorizer. Only the owner can call this.
     * @param _newAuthorizer The address of the new authorizer.
     */
    function setAuthorizer(address _newAuthorizer) external onlyOwner {
        require(_newAuthorizer != address(0), "Cannot set authorizer to zero address");
        authorizer = _newAuthorizer;
        emit AuthorizerSet(_newAuthorizer);
    }

    /**
     * @dev Sets the address of the LevelNFTCollection contract. Only the owner can call this.
     * @param _collectionAddress The deployed address of the Level NFT contract.
     */
    function setLevelNFTCollection(address _collectionAddress) external onlyOwner {

    }


    /**
     * @dev Mints a Level NFT for the caller (`msg.sender`).
     * This function requires a valid signature from the `authorizer`.
     * The signature must be for a message containing the minter's address and the desired level.
     * @param level The level of the NFT to be minted (e.g., 1, 2, 3, 4, 5).
     * @param signature The cryptographic signature produced by the authorizer's private key.
     */
    function mintLevelNFT(uint256 level, bytes calldata signature) external {
        require(levelNFTCollection != address(0), "Level NFT collection not set");
        require(authorizer != address(0), "Authorizer not set");
        require(!hasMintedLevel[msg.sender][level], "You have already minted this level");
        
        // Use the signature itself as a nonce to prevent replay attacks.
        // A signature can only be used once across the entire contract.
        bytes32 sigHash = keccak256(signature);
        require(!usedSignatures[sigHash], "Signature already used");

        // Recreate the message hash that was signed by the backend.
        // It must match exactly: keccak256(abi.encodePacked(msg.sender, level))
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, level));
        
        // Add the standard Ethereum message prefix and recover the signer's address.
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address recoveredSigner = ethSignedMessageHash.recover(signature);

        // Verify that the signer is the authorized address.
        require(recoveredSigner == authorizer, "Invalid signature");

        // If all checks pass, mint the NFT by calling the LevelNFTCollection contract.
        hasMintedLevel[msg.sender][level] = true;
        uint256 newTokenId = ILevelNFTCollection(levelNFTCollection).mint(msg.sender, level);

        // A signature can only be used once across the entire contract.
        usedSignatures[sigHash] = true;
        emit LevelNFTMinted(levelNFTCollection, msg.sender, level, newTokenId);
    }


    /*** @dev Sets the address of the W3PASS contract. Only owner.*/
    function setW3PassAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Cannot be zero address");
        w3PassAddress = _newAddress;
        emit W3PassAddressSet(_newAddress);
    }

    /*** @dev Mints a W3PASS NFT by calling the dedicated contract.
     * It forwards the payment, signature, and Merkle proof.
     * The signature here authorizes the user to *attempt* a mint.
     * The Merkle proof authorizes the *discount*.*/
    function mintW3Pass(
        uint256 _discountTier,
        bytes32[] calldata _merkleProof,
        bytes calldata _signature
    ) external payable {
        require(w3PassAddress != address(0), "W3PASS address not set");
        require(authorizer != address(0), "Authorizer not set");

        // --- Signature Verification ---
        // The signature proves the user is authorized by the backend to mint.
        // We can simplify the signed message to just the user's address.
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address recoveredSigner = ethSignedMessageHash.recover(_signature);
        require(recoveredSigner == authorizer, "Invalid authorizer signature");
        
        // --- Call the W3PASS Contract ---
        // Forward the payment and all necessary data.
        IW3PASS(w3PassAddress).mint{value: msg.value}(msg.sender,_discountTier,_merkleProof);

        // This line is executed only if the mint call above succeeds.
        emit W3PassMinted(msg.sender);
    }

    ////////////////////////////// Public for GUILD ////////////////////////////////////
    ///  Get User Mint Count
    function getUserMintCount(address user) external view returns (uint256) {
        return _usersMint[user].length;
    }

    ///  Get User Collections Count
    function getUserCollectionsCount(address user) external view returns (uint256) {
        return _usersCollections[user].length;
    }
    
    ///  Get User Generate Count
    function getUserPayGenerateFeeCount(address user) external view returns (uint256) {
        return _userGenerationFeeCount[user];
    }
}
