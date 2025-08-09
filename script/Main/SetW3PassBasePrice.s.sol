// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {W3PASS} from "../../src/W3PASS.sol";

/**
 * @title SetW3PassBasePrice
 * @notice A script to update the Merkle Root on the W3PASS contract.
 * @dev This should be run by the owner of the W3PASS contract.
 */
contract SetW3PassBasePrice is Script {

    function run() public {
        
        uint256 newPrice = 1200000000000000;

        // --- 1. Load Configuration from .env file ---
        // This key MUST belong to the owner of the W3PASS contract.
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // The address of the existing W3PASS contract.
        address w3passAddress = vm.envAddress("W3PASS_ADDRESS");

        // Validate configuration
        require(ownerPrivateKey != 0, "PRIVATE_KEY not set");
        require(w3passAddress != address(0), "W3PASS_ADDRESS not set");

        // --- 2. Start Deployment Broadcast ---
        // All subsequent calls will be from the W3PASS owner's address.
        vm.startBroadcast(ownerPrivateKey);

        // --- 3. Call the setMerkleRoot function ---
        W3PASS w3pass = W3PASS(w3passAddress);
        
        console.log("Updating price Root on contract:", w3passAddress);
        w3pass.setBasePrice(newPrice);

        // --- 4. Stop Broadcast ---
        vm.stopBroadcast();

    }
}
