// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignAndVerifyScript is Script {
    using ECDSA for bytes32;
    function run() external {
        vm.startBroadcast();
uint256 privateKey = vm.envUint("MINTER_ADDRESS_KEY_SEPOLIA");
        uint256 privateKey1 = vm.envUint("ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA");

        require(privateKey1 != 0, "ANOTHER_INVALID_MINTER_PRIVATE_KEY_SEPOLIA not set");
        require(privateKey != 0, "MINTER_ADDRESS_KEY_SEPOLIA not set");

        address signer = vm.addr(privateKey1);
        console.log("Signer Address:", signer);

        uint256 timestamp = block.timestamp;

        console.log("Timestamp:");
        console.log(uint32(timestamp));

        bytes32 messageHash = keccak256(abi.encodePacked(signer, timestamp));
        bytes32 ethMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey1, ethMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        console.log("Signature (hex):");
        console.logBytes(signature);

        address recovered = ethMessageHash.recover(signature);
        console.log("Recovered:", recovered);
        console.log("Is Valid:", recovered == signer);

        vm.stopBroadcast();
    }
}