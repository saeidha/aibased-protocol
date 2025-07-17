// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AIBasedNFTFactory} from "../src/AIBasedNFTFactory.sol";

contract SetFee is Script {
    function run() public {
        // The new fee is now a constant value defined inside the function.
        uint256 newFee = 0.00001 ether;

        address factoryAddress = vm.envAddress("FACTORY_ADDRESS_SEPOLIA");
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        
        require(ownerPrivateKey != 0, "PRIVATE_KEY_SEPOLIA not set in .env");

        AIBasedNFTFactory factory = AIBasedNFTFactory(factoryAddress);

        // Start broadcasting from the owner's account
        vm.startBroadcast(ownerPrivateKey);

        // Call the function to set the new fee
        factory.setGenerateFee(newFee);

        vm.stopBroadcast();

        console.log("New generation fee set to:", newFee);
    }
}
