// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IDelegator } from "./interfaces/IDelegator.sol";
import { IWeth } from "./external/IWeth.sol";
import { IDividend } from "./interfaces/IDividend.sol";
import { ICurrentVotes } from "./interfaces/ICurrentVotes.sol";

/// @title Delegator
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract Delegator is IDelegator {
  using SafeMath for uint256;

  /* =================== State Variables ====================== */
  address public ottaAddress;
  /// @notice Total number of wallets lock
  uint256 public delegatorCounter;
  /// @notice Total ethereum to dividend for delegators
  uint256 public totalEthDividend;
  /// @notice Period counter for delegator dividend
  uint256 public periodCounterDelegator;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  /// @notice dönemde kilitledi mi
  mapping(address => mapping(uint256 => bool)) private locked;
  /// @notice Means the yotta dividend share right of the user within the period
  mapping(address => mapping(uint256 => bool)) public receiveDividendDelegator;
  /// @notice Importing current votes methods
  ICurrentVotes public meshVotes;
  ICurrentVotes public ottaVotes;
  IDividend public dividend;

  /* =================== Constructor ====================== */
  constructor(address _ottaAddress, address _meshAddress) {
    isLockingEpoch = true;
    ottaAddress = _ottaAddress;
    ottaVotes = ICurrentVotes(_ottaAddress);
    meshVotes = ICurrentVotes(_meshAddress);
  }

  /* =================== Functions ====================== */
  receive() external payable {}

  /* =================== External Functions ====================== */
  /// @inheritdoc IDelegator
  function setEpochForDelegatorDividend(bool epoch)
    external
    override
    returns (bool state, uint256 totalEth)
  {
    require(msg.sender == ottaAddress, "Only Otta");
    isLockingEpoch = epoch;
    if (isLockingEpoch) {
      totalEthDividend = address(this).balance;
      delegatorCounter = 0;
      periodCounterDelegator += 1;
    }
    return (isLockingEpoch, totalEthDividend);
  }

  /// @notice
  function lock() external {
    require(isLockingEpoch, "Not epoch");
    require(dividend.getPeriod() != 0, "not start");
    require(
      ottaVotes.getCurrentVotes(msg.sender) == 20*10**18 &&
        meshVotes.getCurrentVotes(msg.sender) == 0,
      "not delegator"
    );
    require(!locked[msg.sender][periodCounterDelegator], "locked");
    locked[msg.sender][periodCounterDelegator] = true;
    delegatorCounter += 1;
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user
  function getDividend(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_account][periodCounterDelegator], "not locked");
    require(
      ottaVotes.getCurrentVotes(_account) == 20*10**18 &&
        meshVotes.getCurrentVotes(_account) == 0,
      "not delegator"
    );
    require(
      !receiveDividendDelegator[_account][periodCounterDelegator],
      "Already received"
    );
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    receiveDividendDelegator[_account][periodCounterDelegator] = true;
    uint256 _dividendQuantity = totalEthDividend.div(delegatorCounter);
    _userAddress.transfer(_dividendQuantity);
  }

  /// @notice Setting dividend contract address
  /// @param _dividendAddress address of dividend contract
  function setDividend(address _dividendAddress) public returns (address) {
    dividend = IDividend(_dividendAddress);
    return _dividendAddress;
  }
}
