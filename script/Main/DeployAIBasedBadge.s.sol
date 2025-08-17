// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {AIBasedBadge} from "../../src/AIBasedBadge.sol";
import "forge-std/console.sol";

contract DeployAIBasedBadge is Script {
    
    function run() public {
  
        // deploy();
        addFactory(0x418737EC22F93e95dD1dDE7860A718D3E3a4d886);
    }

    function deploy() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set in .env");

        vm.startBroadcast(deployerPrivateKey);

        address[] memory factories = new address[](3);
        factories[0] = 0x418737EC22F93e95dD1dDE7860A718D3E3a4d886;
        factories[1] = 0x68F3c44093440258Ee5Afde3B0cdF39a3Bf43e9F;
        factories[2] = 0x179Ed73435F83fBBC863f576948be1C92120539d;

        AIBasedBadge badge = new AIBasedBadge(factories);

        vm.stopBroadcast();
        
        console.log("AIBasedBadge deployed at:", address(badge));

    }

    function addFactory(address factoryAddress) public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address badgeAddress = vm.envAddress("BADGE_ADDRESS");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set in .env");
        require(badgeAddress != address(0), "BADGE_ADDRESS not set in .env");

        vm.startBroadcast(deployerPrivateKey);

        AIBasedBadge badge = AIBasedBadge(badgeAddress);
        badge.addFactory(factoryAddress);

        vm.stopBroadcast();
        
        console.log("Factory added to AIBasedBadge at:", badgeAddress);
    }

    function removeFactory(address factoryAddress) public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address badgeAddress = vm.envAddress("BADGE_ADDRESS");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set in .env");
        require(badgeAddress != address(0), "BADGE_ADDRESS not set in .env");

        vm.startBroadcast(deployerPrivateKey);

        AIBasedBadge badge = AIBasedBadge(badgeAddress);
        badge.removeFactory(factoryAddress);

        vm.stopBroadcast();
        
        console.log("Factory removed from AIBasedBadge at:", badgeAddress);
    }
}
