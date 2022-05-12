// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ICoordinator } from "./interfaces/ICoordinator.sol";
import { IWeth } from "./external/IWeth.sol";
import { IDividend } from "./interfaces/IDividend.sol";
import { ICurrentVotes } from "./interfaces/ICurrentVotes.sol";

/// @title Coordinator
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract Coordinator is ICoordinator {
  using SafeMath for uint256;

  /* =================== State Variables ====================== */
  address public ottaAddress;
  address public timelockForOtta;
  /// @notice Total number of wallets lock
  uint256 public coordinatorCounter;
  /// @notice Total ethereum to dividend for delegators
  uint256 public totalEthDividend;
  /// @notice Period counter for coordinator dividend
  uint256 public periodCounterCoordinator;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  bool public isLockDividend;
  /// @notice dönemde kilitledi mi
  mapping(address => mapping(uint256 => bool)) private locked;
  /// @notice Means the yotta dividend share right of the user within the period
  mapping(address => mapping(uint256 => bool))
    public receiveDividendCoordinator;
  /// @notice Importing current votes methods
  ICurrentVotes public meshVotes;
  ICurrentVotes public ottaVotes;
  IDividend public dividend;

  /* =================== Constructor ====================== */
  constructor(address _ottaAddress, address _meshAddress, address _timelockForOtta) {
    isLockingEpoch = true;
    ottaAddress = _ottaAddress;
    ottaVotes = ICurrentVotes(_ottaAddress);
    meshVotes = ICurrentVotes(_meshAddress);
    timelockForOtta = _timelockForOtta;
  }

  /* =================== Functions ====================== */
  receive() external payable {}

  /* =================== External Functions ====================== */
  /// @inheritdoc ICoordinator
  function setEpochForCoordinatorDividend(bool epoch)
    external
    override
    returns (bool state, uint256 totalEth)
  {
    require(msg.sender == ottaAddress, "Only Otta");
    isLockingEpoch = epoch;
    if (isLockingEpoch) {
      totalEthDividend = address(this).balance;
      coordinatorCounter = 0;
      periodCounterCoordinator += 1;
    }
    return (isLockingEpoch, totalEthDividend);
  }

  function setLockDividend(bool _status) external override {
    require(msg.sender == timelockForOtta, "only timelock for otta dao"); //delegator
    isLockDividend = _status; // true durumunda delegator coordinator ın kar payını kilitlemiş oluyor***************
  }

  /// @notice
  function lock() external {
    require(isLockingEpoch, "Not epoch");
    require(dividend.getPeriod() != 0, "not start");
    require(!isLockDividend, "locked");
    require(
      ottaVotes.getCurrentVotes(msg.sender) == 0 &&
        meshVotes.getCurrentVotes(msg.sender) == 2*10**18,
      "not coordinator"
    );
    require(!locked[msg.sender][periodCounterCoordinator], "locked");
    locked[msg.sender][periodCounterCoordinator] = true;
    coordinatorCounter += 1;
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user
  function getDividend(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(!isLockDividend, "locked");
    require(locked[_account][periodCounterCoordinator], "not locked");
    require(
      ottaVotes.getCurrentVotes(_account) == 0 &&
        meshVotes.getCurrentVotes(_account) == 2*10**18,
      "not coordinator"
    );
    require(
      !receiveDividendCoordinator[_account][periodCounterCoordinator],
      "Already received"
    );
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    receiveDividendCoordinator[_account][periodCounterCoordinator] = true;
    uint256 _dividendQuantity = totalEthDividend.div(coordinatorCounter);
    _userAddress.transfer(_dividendQuantity);
  }

  /// @notice Setting dividend contract address
  /// @param _dividendAddress address of dividend contract
  function setDividend(address _dividendAddress) public returns (address) {
    dividend = IDividend(_dividendAddress);
    return _dividendAddress;
  }
}
