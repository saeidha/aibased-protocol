// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {AIBasedNFTFactory} from "../../src/AIBasedNFTFactory.sol";
import "forge-std/console.sol";
import {W3PASS} from "../../src/W3PASS.sol";

contract SetW3PassInFactory is Script {
    function run() public returns (AIBasedNFTFactory) {

        AIBasedNFTFactory factory = AIBasedNFTFactory(vm.envAddress("FACTORY_ADDRESS"));
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address authorizer = vm.envAddress("AUTHORIZER_ADDRESS");
        W3PASS w3pass = W3PASS(vm.envAddress("W3PASS_ADDRESS"));
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set in .env");

        vm.startBroadcast(deployerPrivateKey);


        // Configure the factory to link it to the set LevelNFTCollection
        console.log("Setting Level NFT Collection on the factory...");
        factory.setW3PassAddress(address(w3pass));
        w3pass.setFactoryAddress(address(factory));

        vm.stopBroadcast();
        
        console.log("AIBasedNFTFactory deployed at:", address(factory));
        console.log("Next step: Add this address to your .env file as FACTORY_ADDRESS");

        return factory;
    }
}