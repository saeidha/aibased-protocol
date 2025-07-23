// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {W3PASS} from "../src/W3PASS.sol";

/**
 * @title SetMerkleRoot
 * @notice A script to update the Merkle Root on the W3PASS contract.
 * @dev This should be run by the owner of the W3PASS contract.
 */
contract SetMerkleRoot is Script {

    function run() public {
        
        bytes32 _newRoot = vm.envBytes32("INITIAL_MERKLE_ROOT");
        // --- 1. Load Configuration from .env file ---
        // This key MUST belong to the owner of the W3PASS contract.
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        
        // The address of the existing W3PASS contract.
        address w3passAddress = vm.envAddress("W3PASS_ADDRESS_SEPOLIA");

        // Validate configuration
        require(ownerPrivateKey != 0, "PRIVATE_KEY_SEPOLIA not set");
        require(w3passAddress != address(0), "W3PASS_ADDRESS_SEPOLIA not set");
        require(_newRoot != bytes32(0), "INITIAL_MERKLE_ROOT not set");

        // --- 2. Start Deployment Broadcast ---
        // All subsequent calls will be from the W3PASS owner's address.
        vm.startBroadcast(ownerPrivateKey);

        // --- 3. Call the setMerkleRoot function ---
        W3PASS w3pass = W3PASS(w3passAddress);
        
        console.log("Updating Merkle Root on contract:", w3passAddress);
        w3pass.setMerkleRoot(_newRoot);

        // --- 4. Stop Broadcast ---
        vm.stopBroadcast();

    }
}
