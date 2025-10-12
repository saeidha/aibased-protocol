# AI-Based NFT Creator & W3Pass Smart Contracts


![alt text](https://github.com/saeidha/aibased-protocol/blob/main/eyURIeFSmfFgyxJn5OQq8.png?raw=true)


[](https://opensource.org/licenses/MIT)
[](https://www.google.com/search?q=https://github.com/YOUR_USERNAME/YOUR_REPO/issues)
[](https://www.google.com/search?q=https://github.com/YOUR_USERNAME/YOUR_REPO/network/members)
[](https://www.google.com/search?q=https://github.com/YOUR_USERNAME/YOUR_REPO/stargazers)

Welcome to the official smart contracts repository for **aibased.app**\! 🚀
This project forms the core blockchain infrastructure of our platform, including the contracts for the NFT creator factory, W3Pass system, user experience points (XP), and more.

-----

## ✨ Features

  * **NFT Creator Factory:** Allows users to easily create and manage their own NFT collections.
  * **XP & Leveling System:** Users earn XP through platform activity, leveling up to unlock special rewards and perks.
  * **W3Pass (Web3 Pass):** A special NFT that grants holders access to premium tools and exclusive features on the platform.
  * **Gas Optimized:** Contracts are carefully written to minimize transaction costs (gas fees).
  * **Secure & Reliable:** Developed with the best security practices and patterns in mind.
  * **AIAgent:**

-----

## 🏁 Getting Started

Follow these instructions to set up and run the project on your local machine.

### Prerequisites

Ensure you have the following tools installed on your system:

  * [**Foundry**](https://book.getfoundry.sh/getting-started/installation): A powerful toolkit for Solidity-based smart contract development.
  * [**Git**](https://git-scm.com/): For cloning the project repository.

### Installation & Setup

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
    cd YOUR_REPO
    ```

2.  **Install dependencies:**

    ```bash
    forge install
    ```

3.  **Create an environment file:**
    Create a file named `.env` in the project root. You can copy the example file to get started:

    ```bash
    cp .env.example .env
    ```

    Then, edit the `.env` file with your own information:

    ```env
    # RPC URL for Sepolia Testnet
    SEPOLIA_RPC_URL="https://rpc.sepolia.org"

    # RPC URL for Ethereum Mainnet
    MAINNET_RPC_URL="YOUR_MAINNET_RPC_URL"

    # Your private key for deployment (use a burner wallet for testing)
    PRIVATE_KEY="YOUR_WALLET_PRIVATE_KEY"

    # Etherscan API key for contract verification
    ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
    ```

    **IMPORTANT:** Never commit your `.env` file or expose your private keys. For development, always use a burner wallet that does not hold real funds.

-----

## 🛠️ Usage & Deployment

Deployment scripts are located in the `script/` directory. Before running any script, ensure your `.env` file is configured correctly.

### ABI Generation

Use these commands to generate the necessary ABI files for each smart contract.

```bash
forge inspect src/AIBasedNFTFactory.sol:AIBasedNFTFactory abi --json > AIBasedNFTFactory.json
forge inspect src/NFTCollection.sol:NFTCollection abi --json > NFTCollection.json
forge inspect src/LevelNFTCollection.sol:LevelNFTCollection abi --json > LevelNFTCollection.json
forge inspect src/W3PASS.sol:W3PASS abi --json > W3PASS.json
```

### Testnet (Sepolia) Deployment

These commands are for deploying and testing the contracts on the Sepolia testnet.

```bash
# Deploy Factory
forge script script/DeployFactorySepolia.s.sol:DeployFactory --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

# Deploy Level NFT and link to factory
forge script script/DeployAndLinkLevelNFTSepolia.s.sol:DeployAndLinkLevelNFT --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

# Deploy W3Pass
forge script script/DeployW3PassSepolia.s.sol:DeployW3Pass --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

*For other test scripts, please refer to the `script/` directory.*

### Mainnet Deployment

**⚠️ CAUTION: These commands will deploy contracts to the Ethereum mainnet and will incur real costs.**

```bash
# Deploy Factory
forge script script/Main/DeployFactory.s.sol:DeployFactory --rpc-url $MAINNET_RPC_URL --broadcast --verify -vvvv

# Deploy Level NFT
forge script script/Main/DeployAndLinkLevelNFT.s.sol:DeployAndLinkLevelNFT --rpc-url $MAINNET_RPC_URL --broadcast --verify -vvvv

# Deploy W3Pass
forge script script/Main/DeployW3Pass.s.sol:DeployW3Pass --rpc-url $MAINNET_RPC_URL --broadcast --verify -vvvv

# Set W3Pass Price
forge script script/Main/SetW3PassBasePrice.s.sol:SetW3PassBasePrice --rpc-url $MAINNET_RPC_URL --broadcast -vvvv
```

*To see the full deployment flow, review the scripts in the `script/Main/` directory.*

-----

## Contributing Guide

We welcome contributions of all kinds\! If you'd like to help improve the project, please follow these steps:

1.  **Fork the Project:** Fork this repository to your own GitHub account.
2.  **Create a New Branch:** Create a feature branch for your changes.
    ```bash
    git checkout -b feature/YourAmazingFeature
    ```
3.  **Commit Your Changes:** Make your changes and commit them with a clear message.
    ```bash
    git commit -m "Add some amazing feature"
    ```
4.  **Push to the Branch:** Push your changes to your forked repository.
    ```bash
    git push origin feature/YourAmazingFeature
    ```
5.  **Open a Pull Request:** Open a Pull Request back to this original repository so we can review your changes.

If you find a bug or have a feature request, please open a new **Issue**. We appreciate your help\!

-----

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](https://www.google.com/search?q=LICENSE) file for more details.

**Copyright (c) 2024 aibased.app**
