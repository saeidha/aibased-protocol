// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LockToken} from "../src/LockToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// A simple Mock ERC20 for testing purposes
contract MockERC20 is IERC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;
    string public name = "Mock Token";
    string public symbol = "MCK";
    uint8 public decimals = 18;
function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }