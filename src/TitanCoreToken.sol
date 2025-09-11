// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title TitanCoreToken
 * @author Gemini
 * @notice A feature-rich ERC20 token with vesting, fees, blacklisting, and more.
 */
contract TitanCoreToken is
    Context,
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Capped,
    ERC20Permit,
    ERC20Snapshot,
    AccessControlEnumerable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant VESTING_MANAGER_ROLE = keccak256("VESTING_MANAGER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant SUPPLY_MANAGER_ROLE = keccak256("SUPPLY_MANAGER_ROLE");
    bytes32 public constant DIVIDEND_MANAGER_ROLE = keccak256("DIVIDEND_MANAGER_ROLE");

    // --- Fee Properties ---
    address public feeWallet;
    uint256 public transferFeeBps; // Fee in basis points (1 bps = 0.01%)
    mapping(address => bool) private _isExcludedFromFee;

    // --- Blacklist Properties ---
    mapping(address => bool) private _isBlacklisted;

    // --- Vesting Properties ---
    struct VestingSchedule {
        address beneficiary;
        uint256 cliffTimestamp;
        uint256 startTimestamp;
        uint256 durationSeconds;
        uint256 slicePeriodSeconds;
        bool revocable;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool revoked;
    }

    bytes32[] private _vestingScheduleIds;
    mapping(bytes32 => VestingSchedule) private _vestingSchedules;
    mapping(address => bytes32[]) private _holderVestingScheduleIds;

    // --- Token Vault / Locking ---
    struct Lock {
        uint256 amount;
        uint256 unlockTimestamp;
    }
    mapping(address => Lock[]) private _locks;
    mapping(address => uint256) private _lockedBalance;

    // --- Advanced Burn ---
    uint256 public autoBurnRateBps;
    uint256 public totalAutoBurned;

    // --- Supply Management (Inflation) ---
    uint256 public inflationRateBps;
    uint256 public inflationPeriodSeconds;
    uint256 public lastInflationTimestamp;

    // --- Delegated Transfers (EIP-3009) ---
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;
    bytes32 private constant TRANSFER_AUTHORIZATION_TYPEHASH =
        keccak256(
            "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
        );

    // --- Signature Minting ---
    address private _signatureMinter;
    mapping(uint256 => bool) private _usedNonces;

    // --- Transfer Limits ---
    uint256 public maxTransferPerTx;
    mapping(address => uint256) private _dailyTransferred;
    mapping(address => uint256) private _lastTransferDay;

    // --- Dividends ---
    IERC20 public dividendToken;
    uint256 public totalDividendsDistributed;
    mapping(address => uint256) public withdrawnDividends;
    mapping(uint256 => uint256) public snapshotDividendPerToken;
    uint256 public lastDividendSnapshotId;

    // --- Events ---
    event FeeWalletChanged(address indexed newWallet);
    event TransferFeeChanged(uint256 newFeeBps);
    event FeeExclusionSet(address indexed account, bool isExcluded);
    event AccountBlacklisted(address indexed account);
    event AccountUnblacklisted(address indexed account);
    event VestingScheduleCreated(
        bytes32 indexed scheduleId,
        address indexed beneficiary,
        uint256 amount,
        uint256 duration
    );
    event VestingTokensReleased(bytes32 indexed scheduleId, uint256 amount);
    event VestingScheduleRevoked(bytes32 indexed scheduleId);
    event TokensLocked(
        address indexed user,
        uint256 amount,
        uint256 unlockTimestamp
    );
    event TokensUnlocked(
        address indexed user,
        uint256 lockId,
        uint256 amount
    );
    event AutoBurnRateSet(uint256 newRateBps);
    event InflationSet(uint256 rateBps, uint256 periodSeconds);
    event InflationExecuted(uint256 mintedAmount);
    event AuthorizationUsed(
        address indexed authorizer,
        bytes32 indexed nonce
    );
    event AuthorizationCanceled(
        address indexed authorizer,
        bytes32 indexed nonce
    );
    event SignatureMinterSet(address indexed newSigner);
    event TokensRedeemed(address indexed redeemer, uint256 amount);
    event TransferLimitsSet(uint256 maxPerTx);
    event DividendsDistributed(
        address indexed token,
        uint256 snapshotId,
        uint256 totalAmount
    );
    event DividendWithdrawn(address indexed user, uint256 amount);

    /**
     * @dev Constructor
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 cap,
        uint256 initialSupply,
        address initialFeeWallet
    ) ERC20(name, symbol) ERC20Capped(cap) ERC20Permit(name) {
        require(
            initialFeeWallet != address(0),
            "Fee wallet cannot be zero address"
        );

        feeWallet = initialFeeWallet;
        transferFeeBps = 50; // Default 0.5% fee

        address deployer = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);

        // Grant all roles to the deployer for initial setup
        _grantRole(MINTER_ROLE, deployer);
        _grantRole(PAUSER_ROLE, deployer);
        _grantRole(SNAPSHOT_ROLE, deployer);
        _grantRole(BLACKLISTER_ROLE, deployer);
        _grantRole(FEE_MANAGER_ROLE, deployer);
        _grantRole(VESTING_MANAGER_ROLE, deployer);
        _grantRole(GUARDIAN_ROLE, deployer);
        _grantRole(BURNER_ROLE, deployer);
        _grantRole(SUPPLY_MANAGER_ROLE, deployer);
        _grantRole(DIVIDEND_MANAGER_ROLE, deployer);

        // Exclude deployer and fee wallet from fees by default
        _isExcludedFromFee[deployer] = true;
        _isExcludedFromFee[feeWallet] = true;

        if (initialSupply > 0) {
            _mint(deployer, initialSupply);
        }
        lastInflationTimestamp = block.timestamp;
    }

    // --- Core Overrides ---

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable, ERC20Snapshot) {
        require(!_isBlacklisted[from], "Sender is blacklisted");
        require(!_isBlacklisted[to], "Recipient is blacklisted");
        require(
            balanceOf(from) - _lockedBalance[from] >= amount,
            "Insufficient unlocked balance"
        );

        if (maxTransferPerTx > 0) {
            require(
                amount <= maxTransferPerTx,
                "Transfer exceeds max limit per transaction"
            );
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Capped) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        super._mint(to, amount);
    }

    function _transfer(
