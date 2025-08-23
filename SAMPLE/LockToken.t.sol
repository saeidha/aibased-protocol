// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LockToken} from "../src/LockToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockToken is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Events ---
    event TokensLocked(address indexed user, uint256 lockId, uint256 amount, uint256 unlockTime);
    event TokensWithdrawn(address indexed user, uint256 lockId, uint256 amount);
    event LockExtended(uint256 indexed lockId, uint256 newUnlockTime);
    event EmergencyWithdrawal(address indexed token, address indexed to, uint256 amount);

// --- Structs ---
    struct Lock {
        address owner;
        uint256 amount;
        uint256 unlockTime;
        bool active; // To mark if the lock has been withdrawn
    }
    // --- State Variables ---
    IERC20 public immutable lockToken;
    Lock[] public locks;

    mapping(address => uint256[]) public userLockIds;
    mapping(address => uint256) public userTotalLockedAmount;
    uint256 public totalLocked;

    // --- Constructor ---
    constructor(address _tokenAddress) Ownable(msg.sender) {
                require(_tokenAddress != address(0), "Token address cannot be zero");
                lockToken = IERC20(_tokenAddress);
    }

    // --- Core User Functions ---

    /**
     * @notice Locks a specified amount of tokens for a given duration.
     * @dev The user must first approve this contract to spend their tokens.
     * @param _amount The amount of tokens to lock.
     * @param _duration The lock duration in seconds.
     */
        function lock(uint256 _amount, uint256 _duration) external whenNotPaused {
                    require(_amount > 0, "Amount must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");
        uint256 lockId = locks.length;
        uint256 unlockTime = block.timestamp + _duration;
         locks.push(Lock({
            owner: msg.sender,
            amount: _amount,
            unlockTime: unlockTime,
            active: true
        }));

        userLockIds[msg.sender].push(lockId);
        userTotalLockedAmount[msg.sender] += _amount;
        totalLocked += _amount;

        emit TokensLocked(msg.sender, lockId, _amount, unlockTime);
        lockToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Withdraws the tokens from a specific lock after it has expired.
     * @param _lockId The ID of the lock to withdraw from.
     */

    function withdraw(uint256 _lockId) external whenNotPaused {
        Lock storage userLock = locks[_lockId];
        require(userLock.owner == msg.sender, "Not lock owner");
        require(userLock.active, "Lock already withdrawn");
        require(block.timestamp >= userLock.unlockTime, "Lock period not over yet");
        uint256 amount = userLock.amount;
