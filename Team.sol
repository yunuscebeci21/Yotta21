// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ITeam } from "./interfaces/ITeam.sol";
import { IWeth } from "./external/IWeth.sol";
import { IDividend } from "./interfaces/IDividend.sol";

/// @title Team
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract Team is ITeam {
  using SafeMath for uint256;

  /* =================== State Variables ====================== */
  /// @notice Address of Otta token
  address public ottaAddress;
  /// @notice Address of Yotta token
  address public yottaAddress;
  /// @notice Total number of wallets locking Yotta tokens
  uint256 public walletCounter;
  /// @notice Total locked Yotta token amount
  uint256 public totalLockedYotta;
  /// @notice Total ethereum to dividend
  uint256 public totalEthDividend;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  /// @notice Holds relation of address and locked otta token amount
  mapping(address => uint256) private locked;
  /// @notice Period counter for yotta dividend
  uint256 public periodCounterYotta;
  /// @notice Means the yotta dividend share right of the user within the period
  mapping(address => mapping(uint256 => bool)) public receiveDividendYotta;
  /// @notice Importing Yotta token methods
  ERC20 public yotta;
  /// @notice Importing Dividend contract methods
  IDividend public dividend;

  /* =================== Constructor ====================== */
  constructor(address _ottaAddress, address _yottaAddress) {
    isLockingEpoch = true;
    require(_ottaAddress != address(0), "Zero address");
    ottaAddress = _ottaAddress;
    require(_yottaAddress != address(0), "Zero address");
    yottaAddress = _yottaAddress;
    yotta = ERC20(yottaAddress);
  }

  /* =================== Functions ====================== */
  receive() external payable {}

  /* =================== External Functions ====================== */
  /// @inheritdoc ITeam
  function setEpochForTeamDividend(bool epoch)
    external
    override
    returns (bool state, uint256 totalEth)
  {
    require(msg.sender == ottaAddress, "Only Otta");
    isLockingEpoch = epoch;
    if (isLockingEpoch) {
      totalEthDividend = address(this).balance;
      totalLockedYotta = yotta.balanceOf(address(this));
      periodCounterYotta += 1;
    }
    return (isLockingEpoch, totalEthDividend);
  }

  /// @notice recives Yotta token to lock
  /// @param amount The Yotta token amount to lock
  function lockYotta(uint256 amount) external {
    require(isLockingEpoch, "Not epoch");
    require(dividend.getPeriod() != 0, "not start");
    locked[msg.sender] = locked[msg.sender].add(amount);
    totalLockedYotta = totalLockedYotta.add(amount);
    walletCounter += 1;
    bool success = yotta.transferFrom(msg.sender, address(this), amount);
    require(success, "Transfer failed");
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user
  function getDividendYotta(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_account] != 0, "Locked Otta not found");
    require(
      !receiveDividendYotta[_account][periodCounterYotta],
      "Already received"
    );
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    receiveDividendYotta[_account][periodCounterYotta] = true;
    uint256 _yottaQuantity = locked[_account];
    uint256 _percentage = (_yottaQuantity.mul(10**18)).div(totalLockedYotta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    _userAddress.transfer(_dividendQuantity);
  }

  /// @notice Transfers locked Yotta token and dividend to user
  function getDividendAndYottaToken(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_account] != 0, "Locked Otta not found");
    require(
      !receiveDividendYotta[_account][periodCounterYotta],
      "Already received"
    );
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    receiveDividendYotta[_account][periodCounterYotta] = true;
    uint256 _yottaQuantity = locked[_account];
    locked[_account] = 0;
    walletCounter -= 1;
    uint256 _percentage = (_yottaQuantity.mul(10**18)).div(totalLockedYotta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    _userAddress.transfer(_dividendQuantity);
    bool success = yotta.transfer(_account, _yottaQuantity);
    require(success, "transfer failed");
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

  /// @notice Setting dividend contract address
  /// @param _dividendAddress address of dividend contract
  function setDividend(address _dividendAddress) public returns (address) {
    dividend = IDividend(_dividendAddress);
    return _dividendAddress;
  }
}
