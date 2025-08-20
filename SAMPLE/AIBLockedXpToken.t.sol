// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AIBLockedXpToken} from "../src/AIBLockedXpToken.sol";

contract AIBLockedXpTokenTest is Test {

    AIBLockedXpToken public token;
    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);

    function setUp() public {
        vm.startPrank(owner);
        token = new AIBLockedXpToken(owner);
        vm.stopPrank();
    }

    function test_initial_state() public {
        assertEq(token.name(), "AIBLockedXpToken");
        assertEq(token.symbol(), "AIBLXP");
        assertEq(token.owner(), owner);
        assertEq(token.maxSupply(), 100 * 10 * 10**18);
    }

    function test_add_to_whitelist() public {

        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        vm.prank(owner);
        token.addToWhitelist(users);

        assertTrue(token.whitelist(user1));
        assertTrue(token.whitelist(user2));
    }
}