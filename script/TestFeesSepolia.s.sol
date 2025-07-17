// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AIBasedNFTFactory} from "../src/AIBasedNFTFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PayFee is Script {
    function run() public {
        // Load contract address and user's private key from .env
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS_SEPOLIA");
        uint256 userPrivateKey = vm.envUint("ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA");
        address owner = AIBasedNFTFactory(factoryAddress).owner();

        require(userPrivateKey != 0, "ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA not set in .env");

        AIBasedNFTFactory factory = AIBasedNFTFactory(factoryAddress);

        // --- Get the current fee ---
        vm.prank(owner);
        uint256 feeToPay = factory.getFee();
        console.log("Current fee to pay:", feeToPay);
        
        require(feeToPay > 0, "Fee is currently 0, nothing to pay.");

        // --- Pay the fee from the user's account ---
        vm.startBroadcast(userPrivateKey);

        factory.payGenerateFee{value: feeToPay}();

        vm.stopBroadcast();

        console.log("Successfully paid the generation fee of", feeToPay);
    }
}
