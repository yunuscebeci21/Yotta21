// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IDividend } from "./interfaces/IDividend.sol";

/// @title Dividend
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract Dividend is IDividend {
  using SafeMath for uint256;

  /* =================== State Variables ====================== */
  /// @notice Address of manager contract
  address public manager;
  /// @notice Address of Otta
  address public ottaTokenAddress;
  /// @notice Address of Locked Otta contract
  address public lockedOtta;
  /// @notice Total number of wallets locking Otta tokens
  uint256 public walletCounter;
  /// @notice Total locked Otta token amount
  uint256 public totalLockedOtta;
  /// @notice Total ethereum to dividend
  uint256 public totalEthDividend;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice Period counter for dividend
  uint256 public periodCounter;
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  /// @notice Holds relation of address and locked otta token amount
  mapping(address => uint256) private locked;
  /// @notice Means the dividend share right of the user within the period
  mapping(address => mapping(uint256 => bool)) public receiveDividend;
  /// @notice Importing Otta token methods
  ERC20 public ottaToken;

  /* =================== Constructor ====================== */
  constructor(
    address _manager,
    address _ottaTokenAddress,
    address _lockedOtta
  ) {
    require(_manager != address(0), "zero address");
    manager = _manager;
    isLockingEpoch = false;
    require(_ottaTokenAddress != address(0), "zero address");
    ottaTokenAddress = _ottaTokenAddress;
    ottaToken = ERC20(ottaTokenAddress);
    require(_lockedOtta != address(0), "zero address");
    lockedOtta = _lockedOtta;
  }

  /* =================== Functions ====================== */
  receive() external payable {}

  /* =================== External Functions ====================== */
  /// @inheritdoc IDividend
  function setEpoch(bool epoch)
    external
    override
    returns (bool state, uint256 totalEth)
  {
    require(msg.sender == ottaTokenAddress, "Only Otta");
    isLockingEpoch = epoch;
    if (isLockingEpoch) {
      totalEthDividend = address(this).balance;

      uint256 _amount = ottaToken.balanceOf(lockedOtta);
      locked[manager] = _amount;
      uint256 _ottaAmount = ottaToken.balanceOf(address(this));
      totalLockedOtta = _ottaAmount.add(_amount);
      walletCounter += 1;
      periodCounter += 1;
      emit OttaTokenLocked(manager, _amount);
    }
    return (isLockingEpoch, totalEthDividend);
  }

  /// @notice recives otta token to lock
  /// @param amount The otta token amount to lock
  function lockOtta(uint256 amount) external {
    require(isLockingEpoch, "Not Epoch");
    locked[msg.sender] = locked[msg.sender].add(amount);
    totalLockedOtta = totalLockedOtta.add(amount);
    walletCounter += 1;
    bool success = ottaToken.transferFrom(msg.sender, address(this), amount);
    require(success, "Transfer failed");
    emit OttaTokenLocked(msg.sender, amount);
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user 
  function getDividend(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_account] != 0, "Locked Otta not found");
    require(!receiveDividend[_account][periodCounter], "Already received");
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    receiveDividend[_account][periodCounter] = true;
    uint256 _ottaQuantity = locked[_account];
    uint256 _percentage = (_ottaQuantity.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    _userAddress.transfer(_dividendQuantity);
  }

  /// @notice Transfers locked Otta token and dividend to user
  function getDividendAndOttaToken(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_account] != 0, "Locked Otta not found");
    require(!receiveDividend[_account][periodCounter], "Already received");
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    receiveDividend[_account][periodCounter] = true;
    uint256 _ottaQuantity = locked[_account];
    locked[_account] = 0;
    walletCounter -= 1;
    uint256 _percentage = (_ottaQuantity.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    _userAddress.transfer(_dividendQuantity);
    bool success = ottaToken.transfer(_account, _ottaQuantity);
    require(success, "transfer failed");
  }

  /// @inheritdoc IDividend
  function getDividendRequesting() external override {
    require(msg.sender == ottaTokenAddress, "Only Otta");
    address payable _userAddress = payable(manager);
    require(_userAddress != address(0), "zero address");
    uint256 _ottaQuantity = locked[manager];
    locked[manager] = 0;
    walletCounter -= 1;
    uint256 _percentage = (_ottaQuantity.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    _userAddress.transfer(_dividendQuantity);
  }
  
  /// @inheritdoc IDividend
  function getPeriod()
     external 
     view 
     override
     returns (uint256)
  {
    return periodCounter;
  }

  /* =================== Public Functions ====================== */
  /// @notice Returns locked otta amount of user
  /// @param _userAddress The address of user
  function getLockedAmount(address _userAddress)
    public
    view
    returns (uint256 lockedAmount)
  {
    return locked[_userAddress];
  }
}