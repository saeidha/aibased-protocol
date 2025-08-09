// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {AIBasedNFTFactory} from "../../src/AIBasedNFTFactory.sol";
import "forge-std/console.sol";

contract DeployFactory is Script {
    function run() public returns (AIBasedNFTFactory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address authorizer = vm.envAddress("AUTHORIZER_ADDRESS");
        address levelNftAddress = vm.envAddress("LEVEL_NFT_COLLECTION");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set in .env");

        vm.startBroadcast(deployerPrivateKey);

        AIBasedNFTFactory factory = new AIBasedNFTFactory();


        // Configure the factory to link it to the set LevelNFTCollection
        console.log("Setting Level NFT Collection on the factory...");
        factory.setLevelNFTCollection(address(levelNftAddress));

        console.log("Setting Authorizer on the factory...");
        factory.setAuthorizer(authorizer);

        vm.stopBroadcast();
        
        console.log("AIBasedNFTFactory deployed at:", address(factory));
        console.log("Next step: Add this address to your .env file as FACTORY_ADDRESS");

        return factory;
    }
}