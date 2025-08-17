// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AIBasedNFTFactory} from "../../src/AIBasedNFTFactory.sol";
import {W3PASS} from "../../src/W3PASS.sol";

/**
 * @title DeployW3Pass
 * @notice Deploys and configures the entire W3PASS system, including the factory.
 */
contract DeployW3Pass is Script {
    function run() public returns (address, address) {
        // --- 1. Load Configuration from .env file ---
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address authorizer = vm.envAddress("AUTHORIZER_ADDRESS");
        bytes32 initialMerkleRoot = vm.envBytes32("INITIAL_MERKLE_ROOT");
        uint256 initialPrice = 1200000000000000;//vm.envUint("INITIAL_W3PASS_PRICE");
        string memory initialBaseURI = vm.envString("W3PASS_BASE_URI");
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        // Validate configuration
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set");
        require(authorizer != address(0), "AUTHORIZER_ADDRESS not set");
        require(initialMerkleRoot != bytes32(0), "INITIAL_MERKLE_ROOT not set");
        require(factoryAddress != address(0), "AUTHORIZER_ADDRESS not set");

        AIBasedNFTFactory factory = AIBasedNFTFactory(factoryAddress);
        // --- 2. Start Deployment Broadcast ---
        vm.startBroadcast(deployerPrivateKey);

        // --- 4. Deploy W3PASS Contract ---
        console.log("Deploying W3PASS...");
        W3PASS w3pass = new W3PASS(
            factoryAddress,
            initialMerkleRoot,
            initialPrice,
            initialBaseURI
        );
        console.log("-> W3PASS deployed at:", address(w3pass));

        // --- 5. Configure the Factory ---
        console.log("Configuring AIBasedNFTFactory...");
        factory.setAuthorizer(authorizer);
        console.log("-> Authorizer set to:", authorizer);
        factory.setW3PassAddress(address(w3pass));
        console.log("-> W3PASS address set on factory.");

        // --- 6. Stop Broadcast ---
        vm.stopBroadcast();

        console.log("\nSystem Deployed and Configured Successfully!");
        return (address(factory), address(w3pass));
    }
}
