// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {AIBasedNFTFactory} from "../../src/AIBasedNFTFactory.sol";
import "forge-std/console.sol";

contract DeployFactory is Script {
    function run() public returns (AIBasedNFTFactory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set in .env");

        vm.startBroadcast(deployerPrivateKey);

        AIBasedNFTFactory factory = new AIBasedNFTFactory();

        vm.stopBroadcast();
        
        console.log("AIBasedNFTFactory deployed at:", address(factory));
        console.log("Next step: Add this address to your .env file as FACTORY_ADDRESS");

        return factory;
    }
}