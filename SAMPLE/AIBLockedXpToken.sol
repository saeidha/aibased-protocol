// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AIBLockedXpToken is ERC20, Ownable {

    uint256 public maxSupply;
    uint256 public totalClaims;
    uint256 public constant MAX_CLAIMS = 100;
    uint256 public constant CLAIM_AMOUNT = 10 * 10**18;
}