// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AIBLockedXpToken} from "../src/AIBLockedXpToken.sol";

contract AIBLockedXpTokenTest is Test {

    AIBLockedXpToken public token;
    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);


}