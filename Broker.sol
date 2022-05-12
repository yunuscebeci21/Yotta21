// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IDelegator } from "./interfaces/IDelegator.sol";
import { IWeth } from "./external/IWeth.sol";
import { IDividend } from "./interfaces/IDividend.sol";
import { ICurrentVotes } from "./interfaces/ICurrentVotes.sol";
import { IOtta } from "./interfaces/IOtta.sol";
import { IBroker } from "./interfaces/IBroker.sol";

/// @title Broker
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract Broker is IBroker {
  using SafeMath for uint256;

  /* =================== State Variables ====================== */
  address public ottaAddress;
  /// @notice Total number of wallets lock
  uint256 public brokerCounter;
  /// @notice Total ethereum to dividend for sales
  uint256 public totalEthDividend;
  /// @notice Period counter for sales dividend
  uint256 public periodCounterBroker;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  /// @notice dönemde kilitledi mi
  mapping(address => mapping(uint256 => bool)) private locked;
  /// @notice Means the yotta dividend share right of the user within the period
  mapping(address => mapping(uint256 => bool)) public receiveDividendBroker;
  /// @notice Importing current votes methods
  IDividend public dividend;
  IOtta public otta;

  /* =================== Constructor ====================== */
  constructor(address _ottaAddress) {
    isLockingEpoch = true;
    ottaAddress = _ottaAddress;
    otta = IOtta(_ottaAddress);
  }

  /* =================== Functions ====================== */
  receive() external payable {}

  /* =================== External Functions ====================== */
  /// @inheritdoc IBroker
  function setEpochForBrokerDividend(bool epoch)
    external
    override
    returns (bool state, uint256 totalEth)
  {
    require(msg.sender == ottaAddress, "Only Otta");
    isLockingEpoch = epoch;
    if (isLockingEpoch) {
      totalEthDividend = address(this).balance;
      brokerCounter = 0;
      periodCounterBroker += 1;
    }
    return (isLockingEpoch, totalEthDividend);
  }

  /// @notice
  function lock() external {
    require(isLockingEpoch, "Not epoch");
    require(dividend.getPeriod() != 0, "not start");
    require(otta.getIsDiscount(msg.sender), "not sales");
    require(!locked[msg.sender][periodCounterBroker], "locked");
    locked[msg.sender][periodCounterBroker] = true;
    brokerCounter += 1;
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user
  function getDividend(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(otta.getIsDiscount(msg.sender), "not sales"); // _account***********
    require(locked[msg.sender][periodCounterBroker], "not locked"); // _account**********
    require(
      !receiveDividendBroker[_account][periodCounterBroker],
      "Already received"
    );
    receiveDividendBroker[_account][periodCounterBroker] = true;
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    uint256 _dividendQuantity = totalEthDividend.div(brokerCounter);
    _userAddress.transfer(_dividendQuantity);
  }

  /// @notice Setting dividend contract address
  /// @param _dividendAddress address of dividend contract
  function setDividend(address _dividendAddress) public returns (address) {
    dividend = IDividend(_dividendAddress);
    return _dividendAddress;
  }
}
