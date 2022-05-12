// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ITeam } from "./interfaces/ITeam.sol";
import { IWeth } from "./external/IWeth.sol";
import { IDividend } from "./interfaces/IDividend.sol";
import { IGroups } from "./interfaces/IGroups.sol";

/// @title Groups
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract Groups is IGroups {
  using SafeMath for uint256;

  /* =================== State Variables ====================== */
  /// @notice Address of Otta token
  address public ottaAddress;
  address public timelockForMesh; // ya set edilicek ya da constructor da verilicek
  address public timelockForOtta; // ya set edilicek ya da constructor da verilicek
  /// @notice Total number of wallets locking Yotta tokens
  uint256 public groupCounter;
  /// @notice Total ethereum to dividend
  uint256 public totalEthDividend;
  /// @notice Period counter for yotta dividend
  uint256 public periodCounterGroups;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  /// @notice Holds relation of address and locked otta token amount
  mapping(address => mapping(uint256 => bool)) private locked;   // okuma fonksiyonu yazabilirsin veya public yap**********************
  /// @notice Means the yotta dividend share right of the user within the period
  mapping(address => mapping(uint256 => bool)) public receiveDividendGroups;
  /// @notice Importing Dividend contract methods
  mapping(string => Group) public infoGroup;

  struct Group {
    address groupAddress;
    bool groupStatus;
    uint256 groupPercentage;
  }

  IDividend public dividend;

  /* =================== Constructor ====================== */
  constructor(address _ottaAddress, address _timelockForOtta, address _timelockForMesh) {
    isLockingEpoch = true;
    require(_ottaAddress != address(0), "Zero address");
    ottaAddress = _ottaAddress;
    timelockForOtta = _timelockForOtta;
    timelockForMesh = _timelockForMesh;
    setGroups();
  }

  /* =================== Functions ====================== */
  receive() external payable {}

  /* =================== External Functions ====================== */
  /// @inheritdoc IGroups
  function setEpochForGroupsDividend(bool epoch)
    external
    override
    returns (bool state, uint256 totalEth)
  {
    require(msg.sender == ottaAddress, "Only Otta");
    isLockingEpoch = epoch;
    if (isLockingEpoch) {
      totalEthDividend = address(this).balance;
      //groupCounter = 0;
      periodCounterGroups += 1;
    }
    return (isLockingEpoch, totalEthDividend);
  }

  function lock(string memory _groupName) external {
    require(isLockingEpoch, "Not epoch");
    require(dividend.getPeriod() != 0, "not start");
    require(infoGroup[_groupName].groupStatus, "not group");
    require(
      infoGroup[_groupName].groupAddress == msg.sender,
      "not group address"
    );
    require(!locked[msg.sender][periodCounterGroups], "locked");
    locked[msg.sender][periodCounterGroups] = true;
    //groupCounter += 1;
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user
  function getDividend(address _account, string memory _groupName)
    external
    override
  {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(infoGroup[_groupName].groupStatus, "not group");
    require(
      infoGroup[_groupName].groupAddress == msg.sender,
      "not group address"
    );
    require(locked[msg.sender][periodCounterGroups], "not locked");
    require(
      !receiveDividendGroups[_account][periodCounterGroups],
      "Already received"
    );
    receiveDividendGroups[_account][periodCounterGroups] = true;
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    //uint256 _dividendQuantity = totalEthDividend.div(groupCounter);
    uint256 _dividendQuantity = totalEthDividend.mul(
      (infoGroup[_groupName].groupPercentage).div(100)
    );
    _userAddress.transfer(_dividendQuantity);
  }

  // kilitlemek(feshetmek) için delegator call eder, feshetmek için koordinatör call eder
  function setGroupStatus(string memory _groupName, bool _status)
    external
    override
  {
    require(
      msg.sender == timelockForOtta || msg.sender == timelockForMesh,
      "only timelock for otta dao"
    );
    infoGroup[_groupName].groupStatus = _status;
  }

  function setGroupAddress(string memory _groupName, address _groupAddress)
    external
    override
  {
    require(msg.sender == timelockForMesh, "only timelock for nft dao");
    require(_groupAddress!=address(0), "zero address");
    infoGroup[_groupName].groupAddress = _groupAddress;
  }

  function setGroupPercentage(string memory _groupName, uint256 _groupPercentage)
    external
    override
  {
    require(msg.sender == timelockForMesh, "only timelock for nft dao");
    require(_groupPercentage > 0 && _groupPercentage < 35, "not range");
    infoGroup[_groupName].groupPercentage = _groupPercentage;
  }

  function addGroup(
    string memory _groupName,
    address _groupAddress,
    uint256 _groupPercentage
  ) external override {
    require(msg.sender == timelockForMesh, "only timelock");
    Group memory _newGroup;
    _newGroup.groupAddress = _groupAddress;
    _newGroup.groupStatus = true;
    _newGroup.groupPercentage = _groupPercentage;
    infoGroup[_groupName] = _newGroup;
  }

  /* =================== Public Functions ====================== */

  /// @notice Setting dividend contract address
  /// @param _dividendAddress address of dividend contract
  function setDividend(address _dividendAddress) public returns (address) {
    dividend = IDividend(_dividendAddress);
    return _dividendAddress;
  }

  function setGroups() internal {
    Group memory _groupFinance;
    Group memory _groupOperation;
    Group memory _groupMarketing;
    Group memory _groupEngineering;
    Group memory _groupCommunity;

    _groupFinance.groupAddress = 0x67E164b59C44308330E8F57D8b29A6ba81d5c628; // newprotocoltest
    _groupFinance.groupStatus = true;
    _groupFinance.groupPercentage = 20;
    infoGroup["Finance"] = _groupFinance;

    _groupOperation.groupAddress = 0x9E06e6B41C0E82F86f858d93e7D79cF324e4fC07; // Account1
    _groupOperation.groupStatus = true;
    _groupOperation.groupPercentage = 20;
    infoGroup["Operation"] = _groupOperation;
    
    _groupMarketing.groupAddress = 0xFc3408640D0c34F2d6C0cb68cd5082eDd3df8FCb; // TestAccount
    _groupMarketing.groupStatus = true;
    _groupMarketing.groupPercentage = 20;
    infoGroup["Marketing"] = _groupMarketing;

    _groupEngineering.groupAddress = 0x940e57183Ef2Ae8355C81Af26c2Ca37F9F0d8D5b; // TestAccount2
    _groupEngineering.groupStatus = true;
    _groupEngineering.groupPercentage = 20;
    infoGroup["Engineering"] = _groupEngineering;

    _groupCommunity.groupAddress = 0x19139cAeA6934f639DacFf6feC59b11876F4AF74; // TestAccount3
    _groupCommunity.groupStatus = true;
    _groupCommunity.groupPercentage = 20;
    infoGroup["Community"] = _groupCommunity;
  }

}
