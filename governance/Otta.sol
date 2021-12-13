// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IDividend } from "../interfaces/IDividend.sol";
import { IPrice } from "../interfaces/IPrice.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title Otta
/// @author Yotta21
/// @notice Otta token ownership provides delegate right and dividend right.
contract Otta is Context, IERC20, IERC20Metadata, KeeperCompatibleInterface {
  using SafeMath for uint256;

  /* ================ Events ================== */
  /// @notice An event thats emitted when price contract address setting
  event PriceSetted(address _otta, address _priceAddress);
  /// @notice An event thats emitted when dividend contract address setting
  event DividendSetted(address _otta, address _dividendAddress);
  /// @notice An event thats emitted when an account buying Otta
  event OttaTokenPurchased(address indexed _resipient, uint256 _ottaAmount);
  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );
  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  /* ================ State Variables ================== */
  /// @notice Address of owner
  address public ownerAddress;
  /// @notice Address of dividend contract
  address public dividendAddress;
  /// @notice Address of LockedOtta contract
  address public lockedOtta;
  /// @notice Address of Timelock contract
  address public timelockAddress;
  /// @notice Tresury Vester 1 address 
  address public treasuryVester1;
  /// @notice Tresury Vester 2 address 
  address public treasuryVester2;
  /// @notice Tresury Vester 3 address 
  address public treasuryVester3;
  /// @notice Tresury Vester 4 address 
  address public treasuryVester4;
  /// @notice Otta token name
  string private _name;
  /// @notice Otta token symbol
  string private _symbol;
  /// @notice Otta token decimals
  uint8 private _decimals;
  /// @notice Day counter for dividend lock time and unlock time
  uint16 public dividendDayCounter;
  /// @notice Total supply of tokens
  uint256 private _totalSupply;
  /// @notice Total locked supply, set zero first
  uint256 public lockedSupply;
  /// @notice Total unlocked supply, set zero first
  uint256 public unlockedSupply;
  /// @notice Chainlink keeper trigger time
  uint256 public immutable interval;
  /// @notice Block Timestamp of trigger from Keeper
  uint256 public lastTimeStamp;
  /// @notice Dividend day
  uint256 public dividendDay;
  /// @notice Lock day
  uint256 public lockDay;
  /// @notice Time when the Dividend counter is 0
  uint256 public dividendTime;
  /// @notice Daily cumulative locked otta fee
  uint256 public lockedOttaFeeBalance;
  /// @notice Quantity to be discount
  uint256 public discountQuantity;
  /// @notice Max mint token - Otta total supply
  uint256 public constant TOTAL_OTTA_AMOUNT = 88000000 * 10**18;
  /// @notice Transfer amount for Initial Finance
  uint256 public constant INITIAL_FINANCE = 3240000 * 10**18;
  /// @notice Transfer amount for Treasury Vester
  uint256 public constant TREASURY_VESTER = 17600000 * 10**18;
  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );
  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
  /// @notice Set status of Otta contract
  bool public isPriceSetted;
  bool public isDividendSetted;
  /// @notice Allowance amounts on behalf of others
  mapping(address => mapping(address => uint256)) private _allowances;
  /// @notice Official record of token balances for each account
  mapping(address => uint256) private _balances;
  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;
  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;
  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;
  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }
  /// @notice Importing dividend contract interface as dividend
  IDividend public dividend;
  /// @notice Importing price contract interface as price
  IPrice public price;

  /*================== Modifiers =====================*/
  /// @notice Throws if the sender is not owner or manager
  modifier onlyOwner() {
    require(msg.sender == ownerAddress, "Only Owner or Manager");
    _;
  }

  /*=============== Constructor ========================*/
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 _interval,
    address _lockedOtta,
    address _timelockAddress,
    address _treasuryVester1,
    address _treasuryVester2,
    address _treasuryVester3,
    address _treasuryVester4
  ) {
    ownerAddress = msg.sender;
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
    interval = _interval;
    lastTimeStamp = block.timestamp;
    dividendDay = 28;
    lockDay = 2;
    discountQuantity = 10000 * 10**18;
    require(_lockedOtta != address(0), "Zero Address");
    lockedOtta = _lockedOtta;
    require(_timelockAddress != address(0), "Zero Address");
    timelockAddress = _timelockAddress;
    require(_treasuryVester1 != address(0), "Zero Address");
    treasuryVester1 = _treasuryVester1;
    require(_treasuryVester2 != address(0), "Zero Address");
    treasuryVester2 = _treasuryVester2;
    require(_treasuryVester3 != address(0), "Zero Address");
    treasuryVester3 = _treasuryVester3;
    require(_treasuryVester4 != address(0), "Zero Address");
    treasuryVester4 = _treasuryVester4;
    _mint(address(this), TOTAL_OTTA_AMOUNT);
    _transfer(address(this), ownerAddress, INITIAL_FINANCE.mul(80).div(100));
    _transfer(address(this), ownerAddress, INITIAL_FINANCE.mul(4).div(100)); // vc address
    _transfer(address(this), lockedOtta, INITIAL_FINANCE.mul(16).div(100));
    _transfer(address(this), treasuryVester1, TREASURY_VESTER.mul(10).div(100));
    _transfer(address(this), treasuryVester2, TREASURY_VESTER.mul(20).div(100));
    _transfer(address(this), treasuryVester3, TREASURY_VESTER.mul(30).div(100));
    _transfer(address(this), treasuryVester4, TREASURY_VESTER.mul(40).div(100));
    lockedSupply = _totalSupply.sub(INITIAL_FINANCE.add(TREASURY_VESTER));
  }

  /* ================ Functions ================== */
  /// @notice The function to be triggered when the otta token will buy
  /// @dev The amount of ethereum sent is calculated based on the otta price.
  /// @dev Otta token is transferred to the caller and the protocol.
  receive() external payable {
    uint256 _ethAmount = msg.value;
    require(msg.sender != address(0), "Zero address");
    require(_ethAmount != 0, "Insufficient eth amount");
    address _userAddress = msg.sender;
    uint256 _ottaPrice = price.getOttaPrice();
    uint256 _tokens = (_ethAmount.mul(10**18)).div(_ottaPrice);
    uint256 _userAllowance = 0;
    if (_tokens >= (discountQuantity)) {
      _userAllowance = _ethAmount.mul(8).div(100);
      payable(_userAddress).transfer(_userAllowance);
    }
    uint256 _lockedOttaFee = _tokens.mul(25).div(100);
    payable(dividendAddress).transfer(_ethAmount.sub(_userAllowance));
    _transferFromContract(msg.sender, _tokens);
    _transferLockedOttaFee(_lockedOttaFee);
    emit OttaTokenPurchased(msg.sender, _tokens);
  }

  /*================== External Functions =====================*/
  /// @notice Chainlink Keeper method calls unlocked method
  function performUpkeep(bytes calldata performData) external override {
    require((block.timestamp - lastTimeStamp) > interval, "not epoch");
    lastTimeStamp = block.timestamp;
    unlocked();
    performData;
  }

  /// @notice Checking the upkeepNeeded condition
  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    performData = checkData;
  }
  
  /// @notice Gets the current votes balance for `account`
  /// @param account The address to get votes balance
  /// @return The number of current votes for `account`
  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /// @notice Determine the prior number of votes for an account as of a block number
  /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
  /// @param account The address of the account to check
  /// @param blockNumber The block number to get the vote balance at
  /// @return The number of votes the account had as of the given block
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint256)
  {
    require(
      blockNumber < block.number,
      "Comp::getPriorVotes: not yet determined"
    );

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  /*================== Public Functions =====================*/
  /// @notice Setting price contract address
  /// @dev Since this contract is deployed before the price contract, the price contract address is set.
  /// @dev Param and return same address
  /// @param '_priceAddress' The price contract address.
  /// @return The price contract address.
  function setPrice(address _priceAddress) public onlyOwner returns (address) {
    require(!isPriceSetted, "Already setted");
    require(_priceAddress != address(0), "Zero address");
    isPriceSetted = true;
    price = IPrice(_priceAddress);
    emit PriceSetted(address(this), _priceAddress);
    return _priceAddress;
  }

  /// @notice Setting dividend contract address
  /// @dev Since this contract is deployed before the dividend contract, the dividend contract address is set.
  /// @dev Param and return same address
  /// @param '_dividendAddress' The dividend contract address.
  /// @return The dividend contract address.
  function setDividend(address _dividendAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isDividendSetted, "Already setted");
    require(_dividendAddress != address(0), "Zero address");
    isDividendSetted = true;
    dividendAddress = _dividendAddress;
    dividend = IDividend(dividendAddress);
    emit DividendSetted(address(this), dividendAddress);
    return dividendAddress;
  }

  /// @notice Setting discount quantity
  /// @dev Can be changed by governance decision
  /// @param '_discountQuantity' The new discount quantity. 
  function setDiscountQuantity(uint256 _discountQuantity)
  public
  returns(uint256)
  {
    require(msg.sender == timelockAddress, "Only Timelock");
    discountQuantity = _discountQuantity;
    return discountQuantity;
  }

  /// @return  The name of the token.
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /// @return The symbol of the token.
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /// @return The decimals of the token.
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  /// @return The total supply of the token.
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /// @return The balance of the account.
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  /// @notice "sperder" value by "owner" for token.
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /// @notice Sets the "spender" value with "sender" tokens
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /// @notice Automatically increases
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /// @notice Automatically decrease
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
    return true;
  }

  /// @notice Moves `amount` tokens from the caller's account to `recipient`
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
  /// `amount` is then deducted from the caller's allowance.
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    _approve(sender, _msgSender(), currentAllowance.sub(amount));
    return true;
  }

  /// @notice Delegate votes from `msg.sender` to `delegatee`
  /// @param delegatee The address to delegate votes to
  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  /// @notice Delegates votes from signatory to `delegatee`
  /// @param delegatee The address to delegate votes to
  /// @param nonce The contract state required to match the signature
  /// @param expiry The time at which to expire the signature
  /// @param v The recovery byte of the signature
  /// @param r Half of the ECDSA signature pair
  /// @param s Half of the ECDSA signature pair
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(_name)),
        getChainId(),
        address(this)
      )
    );
    bytes32 structHash = keccak256(
      abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Comp::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "Comp::delegateBySig: invalid nonce");
    require(
      block.timestamp <= expiry,
      "Comp::delegateBySig: signature expired"
    );
    return _delegate(signatory, delegatee);
  }

  /*================== Internal Functions =====================*/
  /// @notice Triggers every interval time
  /// @dev Unlocks 11500 tokens each time triggered
  /// @dev Unlocked tokens are split into two: 'unlockedSupply' and 'lockedOttaFeeBalance'
  /// @dev Buy is made from 'unlockedSupply'
  /// @dev Transfer for lockedOtta from 'lockedOttaFeeBalance'
  function unlocked() internal {
    if (lockedSupply == 0) {
      dividendDayCounter += 1;
      if (dividendDayCounter == dividendDay) {
        dividend.setEpoch(true);
      }
      if (dividendDayCounter == lockDay + dividendDay) {
        dividend.setEpoch(false);
        dividendDayCounter = 0;
        dividendTime = block.timestamp;
        dividend.getDividendRequesting();
      }
    } else {
      lockedSupply = lockedSupply.sub(11500 * 10**18);
      unlockedSupply = unlockedSupply.add(9200 * 10**18);
      lockedOttaFeeBalance = lockedOttaFeeBalance.add(2300 * 10**18);
      dividendDayCounter += 1;
      if (dividendDayCounter == dividendDay) {
        dividend.setEpoch(true);
      }
      if (dividendDayCounter == lockDay + dividendDay) {
        dividend.setEpoch(false);
        dividendDayCounter = 0;
        dividendTime = block.timestamp;
        dividend.getDividendRequesting();
      }
    }
  }

  /// @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
  /// Requirements:
  /// `owner` cannot be the zero address.
  /// `spender` cannot be the zero address.
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /// @notice Moves `amount` of tokens from `sender` to `recipient`.
  /// Requirements:
  /// `sender` cannot be the zero address.
  /// `recipient` cannot be the zero address.
  /// `sender` must have a balance of at least `amount`.
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance.sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);

    _moveDelegates(delegates[sender], delegates[recipient], amount);
  }

  /// @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
  /// Requirements:
  /// `account` cannot be the zero address.
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);

    // move delegates
    _moveDelegates(address(0), delegates[account], amount);
  }

  /// @notice Destroys `amount` tokens from `account`, reducing the total supply.
  /// Requirements:
  /// `account` cannot be the zero address.
  /// `account` must have at least `amount` tokens.
  function _burn(address account, uint256 amount) internal virtual {
    require(
      msg.sender == address(this),
      "Address without permission to run the function"
    );

    require(account != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balances[account] = accountBalance.sub(amount);
    _totalSupply = _totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }


  /// @notice Transfer function written for the protocol to transfer
  /// from "unlockedSupply" after selling otta tokens
  /// @dev 'sender' this contract
  /// Requirements:
  /// 'recipient' cannot be the zero address.
  /// `sender` must have a balance of at least `amount`.
  function _transferFromContract(address recipient, uint256 amount)
    internal
    virtual
  {
    require(recipient != address(0), "ERC20: transfer to the zero address");
    uint256 senderBalance = unlockedSupply;
    require(senderBalance >= amount, "Insufficient Unlocked Supply!");
    unlockedSupply = unlockedSupply.sub(amount);
    _transfer(address(this), recipient, amount);
  }

  /// @notice Transfer function written for the lockedOtta to transfer
  /// from "lockedOttaFeeBalance" after buying otta tokens
  /// @dev 'sender' this contract
  /// @dev 'recipient' LockedOtta contract
  /// Requirements:
  /// 'recipient' cannot be the zero address.
  /// `sender` must have a balance of at least `amount`.
  function _transferLockedOttaFee(uint256 amount) internal virtual {
    uint256 senderBalance = lockedOttaFeeBalance;
    require(senderBalance >= amount, "Insufficient Protocol Fee Balance!");
    lockedOttaFeeBalance = lockedOttaFeeBalance.sub(amount);
    _transfer(address(this), lockedOtta, amount);
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint256 delegatorBalance = _balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0
          ? checkpoints[srcRep][srcRepNum - 1].votes
          : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0
          ? checkpoints[dstRep][dstRepNum - 1].votes
          : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(
      block.number,
      "Comp::_writeCheckpoint: block number exceeds 32 bits"
    );

    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    chainId = block.chainid;
    return chainId;
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  } 
}
