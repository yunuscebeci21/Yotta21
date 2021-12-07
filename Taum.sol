// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ITaum } from "./interfaces/ITaum.sol";
import { IProtocolVault } from "./interfaces/IProtocolVault.sol";
import { IPrice } from "./interfaces/IPrice.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title Taum
/// @author Yotta21
/// @notice 
contract Taum is
  Context,
  IERC20,
  IERC20Metadata,
  ITaum,
  KeeperCompatibleInterface
{
  using SafeMath for uint256;

  /*================== Events ===================*/
  /// @notice An event thats emitted when Price contract address setting
  event PriceSetted(address _priceAddress);
  /// @notice An event thats emitted when ProtocolVault contract address setting
  event ProtocolVaultSetted(address _protocolVaultAddress);
  /// @notice An event thats emitted when EthereumPool contract address setting
  event EthPoolSetted(address _ethPoolAddress);

  /*================== State Variables ===================*/
  /// @notice Address of dividend contract
  address public dividendAddress;
  /// @notice Address of the Ethereum Pool
  address public ethPoolAddress;
  /// @notice Address of contract creator
  address public ownerAddress;
  /// @notice Token name for taum token
  string private _name;
  /// @notice Token symbol for taum token
  string private _symbol;
  /// @notice Token decimals for taum token
  uint8 private _decimals;
  /// @notice Total supply
  uint256 private _totalSupply;
  /// @notice Yearly percent of total supply
  uint256 public constant YEARLY_VALUE = 0.8760 * 10**18;
  /// @notice Chainlink keeper call time
  uint256 public immutable interval;
  /// @notice Block Timestamp
  uint256 public lastTimeStamp;
  /// @notice Set status of taum
  bool public isPriceSetted;
  bool public isProtocolVaultSetted;
  bool public isEthPoolSetted;
  /// @notice Allowance amounts on behalf of others
  mapping(address => mapping(address => uint256)) private _allowances;
  /// @notice Official record of token balances for each account
  mapping(address => uint256) private _balances;
  /// @notice Importing Price interface as price
  IPrice public price;
  /// @notice Importing Ethereum vault interface as ethVault
  IProtocolVault public protocolVault;

  /* ================ Modifier ================== */
  /// @notice Throws if the sender is not owner or manager
  modifier onlyOwner() {
    require(msg.sender == ownerAddress, "Only Owner Manager");
    _;
  }

  /*=============== Constructor ========================*/
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 _interval,
    address payable _dividendAddress
  ) {
    ownerAddress = msg.sender;
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
    require(_dividendAddress != address(0), "zero address");
    dividendAddress = _dividendAddress;
    interval = _interval;
    lastTimeStamp = block.timestamp;
    _mint(ownerAddress, (10000 * 10**18));
  }

  /*================== Functions =====================*/
  /*================== External Functions =====================*/
  /// @notice Function called when otta token sale is made to the system
  /// @param _taumAmount Quantity of taum token. It must be wei type (10**18)
  function receiver(uint256 _taumAmount) external {
    address payable _userAddress = payable(msg.sender);
    uint256 accountBalance = _balances[msg.sender];
    require(
      accountBalance >= _taumAmount,
      "ERC20: burn amount exceeds balance"
    );
    bool successTransfer = transfer(address(this), _taumAmount);
    require(successTransfer, "Transfer failed");
    (, , uint256 _taumPrice) = price.getTaumPrice(0);
    uint256 _ethAmount = _taumAmount.mul(_taumPrice).div(10**18);
    bool statusInvestment = protocolVault.withdraw(_userAddress, _ethAmount);
    require(statusInvestment, "Insufficient Ether");
    _burn(address(this), _taumAmount);
  }

  /// @inheritdoc ITaum
  function tokenMint(address recipient, uint256 amount) external override {
    require(msg.sender == ethPoolAddress, "Only Ethereum Pool");
    _mint(recipient, amount);
  }

  /// @notice Chainlink Keeper method calls mintProtocol method
  function performUpkeep(bytes calldata performData) external override {
    require((block.timestamp - lastTimeStamp) > interval, "not epoch");
    lastTimeStamp = block.timestamp;
    mintProtocolFee();
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

  /*================== Public Functions =====================*/
  /// @notice Setting price contract address methods
  /// @param _priceAddress The Price contract address.
  function setPrice(address _priceAddress) public onlyOwner returns (address) {
    require(!isPriceSetted, "Already setted");
    require(_priceAddress != address(0), "zero address");
    isPriceSetted = true;
    price = IPrice(_priceAddress);
    emit PriceSetted(_priceAddress);
    return (_priceAddress);
  }

  /// @notice Setting protocol vault contract address
  /// @param _protocolVaultAddress The protocol vault contract address.
  function setProtocolVault(address _protocolVaultAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isProtocolVaultSetted, "Already setted");
    require(_protocolVaultAddress != address(0), "zero address");
    isProtocolVaultSetted = true;
    protocolVault = IProtocolVault(_protocolVaultAddress);
    emit ProtocolVaultSetted(_protocolVaultAddress);
    return (_protocolVaultAddress);
  }

  /// @notice Setting ethereum pool contract address
  /// @param _ethPoolAddress The ethereum pool contract address.
  function setEthPool(address _ethPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isEthPoolSetted, "Already setted");
    require(_ethPoolAddress != address(0), "zero address");
    isEthPoolSetted = true;
    ethPoolAddress = _ethPoolAddress;
    emit EthPoolSetted(ethPoolAddress);
    return (ethPoolAddress);
  }

  /// @return The name of the token.
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

  /*================== Internal Functions =====================*/
  /// @notice Calculate protocol fee and transfers Ether the dividend contract
  function mintProtocolFee() internal {
    uint256 _protocolFee = (_totalSupply.mul(YEARLY_VALUE)).div(100).div(
      365 * 10**18
    );
    (, , uint256 _taumPrice) = price.getTaumPrice(0);
    uint256 _feeQuantity = (_taumPrice.mul(_protocolFee)).div(10**18);
    protocolVault.withdraw(payable(dividendAddress), _feeQuantity);
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
  }

  /// @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
  /// Requirements:
  /// `account` cannot be the zero address.
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /// @notice Destroys `amount` tokens from `account`, reducing the total supply.
  /// Requirements:
  /// `account` cannot be the zero address.
  /// `account` must have at least `amount` tokens.
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balances[account] = accountBalance.sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }
}
