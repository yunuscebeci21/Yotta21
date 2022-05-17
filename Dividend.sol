// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IDividend } from "./interfaces/IDividend.sol";
import { ILPTrade } from "./interfaces/ILPTrade.sol";
import { ILockedOttaMesh } from "./interfaces/ILockedOttaMesh.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import { IUniswapV2Router02 } from "./external/IUniswapV2Router02.sol";


/// @title Dividend
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract Dividend is IDividend, KeeperCompatibleInterface{
  using SafeMath for uint256;

  /* =================== State Variables ====================== */

  struct LPTrade{
    address lpTradeAddress;
    uint percentage;
    bool isActive;
  }

  LPTrade[] public arrayLPTrade;

  address public owner;
  /// @notice Address of team contract
  address public team;
  
  address public delegator;
  address public coordinator;
  address public groups;
  address public broker;
  address public meshNFT;

  /// @notice Address of Otta
  address public ottaTokenAddress;
  /// @notice Address of Locked Otta contract
  address public lockedOttaTeam;
  address public lockedOttaBroker;
  address public lockedOttaMeshNFT;
  address public lockedOttaMesh;
  address public ottaTimelock; 
  address public swapRouterAddress;
  address public ethAddress;
  address public ttffAddress;
  /// @notice Total number of wallets locking Otta tokens
  uint256 public walletCounter;
  /// @notice Total locked Otta token amount
  uint256 public totalLockedOtta;
  /// @notice Total ethereum to dividend
  uint256 public totalEthDividend;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  uint256 public constant DEADLINE = 5 hours;
  /// @notice Period counter for dividend
  uint256 public periodCounter;
  uint256 public lastTimeStamp;

  uint public immutable interval;
  //uint256 public percentageToLpTrade; /* **************************** */
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  /// @notice Holds relation of address and locked otta token amount
  mapping(address => uint256) private locked;
  /// @notice Means the dividend share right of the user within the period
  mapping(address => mapping(uint256 => bool)) public receiveDividend;
  /// @notice Importing Otta token methods
  ERC20 public ottaToken;
  ERC20 public eth;
  ///
  ILockedOttaMesh public mesh;

  IUniswapV2Router02 public swapRouter;

  /* =================== Constructor ====================== */
  constructor(
    address _ottaTokenAddress,
    address _ottaTimelock,
    address _lockedOttaTeam,
    address _lockedOttaBroker,
    address _lockedOttaMeshNFT,
    address _lockedOttaMesh,
    address _ethAddress,
    address _ttffAddress,
    address _swapRouterAddress
  ) {
    owner = msg.sender;
    //isLockingEpoch = false;
    interval = 1 days;
    lastTimeStamp = block.timestamp;
    require(_ottaTokenAddress != address(0), "zero address");
    ottaTokenAddress = _ottaTokenAddress;
    ottaToken = ERC20(ottaTokenAddress);
    ottaTimelock = _ottaTimelock;
    require(_lockedOttaTeam != address(0), "zero address");
    lockedOttaTeam = _lockedOttaTeam;
    lockedOttaBroker = _lockedOttaBroker;
    lockedOttaMeshNFT = _lockedOttaMeshNFT;
    lockedOttaMesh = _lockedOttaMesh;
    mesh = ILockedOttaMesh(_lockedOttaMesh);
    eth = ERC20(_ethAddress);
    ethAddress = _ethAddress;
    ttffAddress = _ttffAddress;
    swapRouterAddress = _swapRouterAddress;
    swapRouter = IUniswapV2Router02(_swapRouterAddress);
    firstLPTrade();
  }

  /* =================== Functions ====================== */
  //receive() external payable {}

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
      totalEthDividend = eth.balanceOf(address(this));
      uint preEthDividend;
      for(uint i=0; i<arrayLPTrade.length; i++){
        if(arrayLPTrade[i].isActive){ // yatırımların yüzdelerinin toplamı %80 den az %0 den fazla olamaz
          ILPTrade lpTrade = ILPTrade(arrayLPTrade[i].lpTradeAddress);
          uint256 _amountToLpTrade = totalEthDividend.mul(arrayLPTrade[i].percentage).div(100);
          preEthDividend = preEthDividend.add(_amountToLpTrade);
          //payable(arrayLPTrade[i].lpTradeAddress).transfer(_amountToLpTrade);
          eth.transfer(arrayLPTrade[i].lpTradeAddress, _amountToLpTrade);
          lpTrade.trade();
        } 
      }
      totalEthDividend = totalEthDividend.sub(preEthDividend); // min %20 olmalı 
      
      uint256 _amountTeam = ottaToken.balanceOf(lockedOttaTeam);
      uint256 _amountForBroker = ottaToken.balanceOf(lockedOttaBroker);
      uint256 _amountForMeshNFT = ottaToken.balanceOf(lockedOttaMeshNFT);
      uint256 _amountForMesh = ottaToken.balanceOf(lockedOttaMesh);
      locked[lockedOttaTeam] = _amountTeam;
      locked[lockedOttaBroker] = _amountForBroker;
      locked[lockedOttaMeshNFT] = _amountForMeshNFT;
      locked[lockedOttaMesh] = _amountForMesh;
      uint256 _ottaAmount = ottaToken.balanceOf(address(this));
      totalLockedOtta = _ottaAmount.add(((_amountTeam.add(_amountForBroker)).add(_amountForMeshNFT)).add(_amountForMesh));
      walletCounter += 4;
      periodCounter += 1;
      emit OttaTokenLocked(lockedOttaTeam, lockedOttaBroker, lockedOttaMesh, totalLockedOtta);
    }
    return (isLockingEpoch, totalEthDividend);
  }

  function setContractAddresses(address[] calldata _addresses) external {
    require(msg.sender == owner, "Only owner");
    team = _addresses[0];
    delegator = _addresses[1];
    coordinator = _addresses[2];
    groups = _addresses[3];
    broker = _addresses[4];
    mesh = ILockedOttaMesh(_addresses[5]);
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
    emit LockedOtta(msg.sender, amount);
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user 
  function getDividend(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_account] != 0, "Locked Otta not found");
    require(!receiveDividend[_account][periodCounter], "Already received");
    address payable _userAddress = payable(_account);
    //require(_userAddress != address(0), "zero address");
    receiveDividend[_account][periodCounter] = true;
    uint256 _ottaQuantity = locked[_account];
    uint256 _percentage = (_ottaQuantity.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    eth.transfer(_userAddress, _dividendQuantity);
  }

  /// @notice Transfers locked Otta token and dividend to user
  function getDividendAndOttaToken(address _account) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_account] != 0, "Locked Otta not found");
    require(!receiveDividend[_account][periodCounter], "Already received");
    address payable _userAddress = payable(_account);
    //require(_userAddress != address(0), "zero address");
    receiveDividend[_account][periodCounter] = true;
    uint256 _ottaQuantity = locked[_account];
    locked[_account] = 0;
    walletCounter -= 1;
    uint256 _percentage = (_ottaQuantity.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    eth.transfer(_userAddress, _dividendQuantity);
    bool success = ottaToken.transfer(_account, _ottaQuantity);
    require(success, "transfer failed");
  }

  /// @inheritdoc IDividend
  function getDividendRequesting() external override {
    require(msg.sender == ottaTokenAddress, "Only Otta");
    address payable _teamAddress = payable(team);
    address payable _brokerAddress = payable(broker);
    address payable _meshNFTAddress = payable(meshNFT);
    require(_teamAddress != address(0) && _brokerAddress != address(0), "zero address");
    uint256 _ottaQuantityTeam = locked[lockedOttaTeam];
    uint256 _ottaQuantityBroker = locked[lockedOttaBroker];
    uint256 _ottaQuantityMeshNFT = locked[lockedOttaMeshNFT];
    locked[lockedOttaTeam] = 0;
    locked[lockedOttaBroker] = 0;
    locked[lockedOttaMeshNFT] = 0;
    walletCounter -= 3;
    uint256 _percentageForTeam = (_ottaQuantityTeam.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantityForTeam = (_percentageForTeam.mul(totalEthDividend)).div(10**18);
    eth.transfer(_teamAddress, _dividendQuantityForTeam);
    uint256 _percentageForBroker = (_ottaQuantityBroker.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantityForBroker = (_percentageForBroker.mul(totalEthDividend)).div(10**18);
    eth.transfer(_brokerAddress, _dividendQuantityForBroker);
    uint256 _percentageForMeshNFT = (_ottaQuantityMeshNFT.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantityForMeshNFT = (_percentageForMeshNFT.mul(totalEthDividend)).div(10**18);
    eth.transfer(_meshNFTAddress, _dividendQuantityForMeshNFT);
  }

  /// @inheritdoc IDividend
  function getMeshDividendRequesting() external override {
    require(msg.sender == ottaTokenAddress, "Only Otta");
    address payable _delegatorAddress = payable(delegator);
    address payable _coordinatorAddress = payable(coordinator);
    address payable _groupsAddress = payable(groups);
    require(_delegatorAddress != address(0) && _coordinatorAddress != address(0) && _groupsAddress != address(0), "zero address");
    uint256 _ottaQuantityForMesh = locked[lockedOttaMesh];
    locked[lockedOttaMesh] = 0;
    walletCounter -= 1;
    uint256 _percentage = (_ottaQuantityForMesh.mul(10**18)).div(totalLockedOtta);
    uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(10**18);
    uint256 _dividendQuantityForDelegator = _dividendQuantity.mul(mesh.getMeshPercentage("Delegator").div(100));
    uint256 _dividendQuantityForCoordinator = _dividendQuantity.mul(mesh.getMeshPercentage("Coordinator").div(100));
    uint256 _dividendQuantityForGroups = _dividendQuantity.mul(mesh.getMeshPercentage("Groups").div(100));
    eth.transfer(_delegatorAddress, _dividendQuantityForDelegator);
    eth.transfer(_coordinatorAddress, _dividendQuantityForCoordinator);
    eth.transfer(_groupsAddress, _dividendQuantityForGroups);
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

  function addLPTrade(address _lpTradeAddress, uint256 _percentageToLPTrade) external {
    require(msg.sender == ottaTimelock, "only otta timelock");
    LPTrade memory lpTrade;
    lpTrade.lpTradeAddress = _lpTradeAddress;
    lpTrade.percentage = _percentageToLPTrade;
    lpTrade.isActive = true;
    arrayLPTrade.push(lpTrade);
    bool success = controlOfLPTradePercentage();
    require(success, "out of range");
  }

  function setPercentageToLPTrade(address _lpTradeAddress, uint256 _percentage)
     external     
  {
    require(msg.sender == ottaTimelock, "only otta timelock");
    for(uint i=0; i<arrayLPTrade.length;i++){
       if(arrayLPTrade[i].lpTradeAddress==_lpTradeAddress){
          arrayLPTrade[i].percentage = _percentage;
       }
    }
    bool success = controlOfLPTradePercentage();
    require(success, "out of range");
  }

  function setActiveToLPTrade(address _lpTradeAddress, bool _status)
     external     
  {
    require(msg.sender == ottaTimelock, "only otta timelock");
    for(uint i=0; i<arrayLPTrade.length;i++){
       if(arrayLPTrade[i].lpTradeAddress==_lpTradeAddress){
          arrayLPTrade[i].isActive = _status;
       }
    }
    bool success = controlOfLPTradePercentage();
    require(success, "out of range");
  }

  /// @notice Chainlink Keeper method calls mintProtocol method
  function performUpkeep(bytes calldata performData) external override {
    require((block.timestamp - lastTimeStamp) > interval, "Not epoch");
    lastTimeStamp = block.timestamp;
    sellToTTFF();
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

  function controlOfLPTradePercentage() internal view returns(bool){
    uint totalPercentage;
    for(uint i=0; i<arrayLPTrade.length; i++){
       if(arrayLPTrade[i].isActive){
          totalPercentage = totalPercentage.add(arrayLPTrade[i].percentage);
       }
    }
    require(totalPercentage>=0 && totalPercentage<=80, "out of lp investment range");
    return true;
  }

  function firstLPTrade() internal {
    LPTrade memory lpTrade;
    lpTrade.lpTradeAddress = 0x9E06e6B41C0E82F86f858d93e7D79cF324e4fC07;
    lpTrade.percentage = 50;
    lpTrade.isActive = true;
    arrayLPTrade.push(lpTrade);
    controlOfLPTradePercentage();
  } 

  function approveComponents() public {
    ERC20 ttff = ERC20(ttffAddress);
    ttff.approve(swapRouterAddress, MAX_INT);
    eth.approve(swapRouterAddress, MAX_INT);
  }

  function sellToTTFF() internal {
    address[] memory _path = new address[](2);
    _path[0] = ethAddress;
    _path[1] = ttffAddress;
    swapRouter.swapExactTokensForTokens(
      eth.balanceOf(address(this)),
      0,
      _path,
      address(this),
      block.timestamp + DEADLINE
    );
  }

}