const { ethers } = require('ethers');
require('dotenv').config();

// Use a different RPC endpoint if the primary one fails
const RPC_URLS = [
    process.env.BASE_RPC,
    'https://base.llamarpc.com',
    'https://base.blockpi.network/v1/rpc/public'
];

async function getProvider() {
    for (const url of RPC_URLS) {
        try {
            const provider = new ethers.JsonRpcProvider(url);
            // Test the connection
            await provider.getNetwork();
            return provider;
        } catch (error) {
            console.log(`Failed to connect to ${url}, trying next...`);
        }
    }
    throw new Error('All RPC endpoints failed');
}

async function retryOperation(operation, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await operation();
        } catch (error) {
            if (i === maxRetries - 1) throw error;
            console.log(`Retry ${i + 1} of ${maxRetries}...`);
            await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1))); // Exponential backoff
        }
    }
}

async function main() {
    // Connect to the network
    const provider = await getProvider();
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    // Factory address
    const factoryAddress = '0x8e49aD54352E8658a7EBb8e6B22A33299832F27D';
    
    // Factory ABI (only the functions we need)
    const factoryABI = [
        "function getCollections() external view returns (address[])"
    ];

    // Collection ABI (only the functions we need)
    const collectionABI = [
        "function owner() external view returns (address)",
        "function withdraw() external",
        "function balanceOf(address) external view returns (uint256)"
    ];

    // Create contract instances
    const factory = new ethers.Contract(factoryAddress, factoryABI, wallet);
    
    try {
        // Get all collections
        const collections = await retryOperation(() => factory.getCollections());
        console.log(`Found ${collections.length} collections`);

        // Process each collection
        for (const collectionAddress of collections) {
            try {
                // Create collection contract instance
                const collection = new ethers.Contract(collectionAddress, collectionABI, wallet);
                
                // Get balance
                const balance = await retryOperation(() => provider.getBalance(collectionAddress));
                console.log(`Collection ${collectionAddress} balance: ${balance} wei`);

                if (balance > 0n) {
                    try {
                        // Try to withdraw
                        console.log(`Attempting to withdraw from ${collectionAddress}...`);
                        const tx = await retryOperation(() => collection.withdraw());
                        await tx.wait();
                        console.log(`Successfully withdrew from ${collectionAddress}`);
                    } catch (withdrawError) {
                        console.error(`Failed to withdraw from ${collectionAddress}:`, withdrawError.message);
                    }
                }
            } catch (error) {
                console.error(`Error processing collection ${collectionAddress}:`, error.message);
            }
        }
    } catch (error) {
        console.error('Error:', error);
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    }); 