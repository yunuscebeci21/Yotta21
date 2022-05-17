// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title OttaTokenCrowdsale
/// @author Yotta21
contract OttaTokenCrowdsale is KeeperCompatibleInterface {
  using SafeMath for uint256;

  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  address public owner;
  address public ottaAddress;
  address public dividend;
  address public ottaTimelock; 
  // How many token units a buyer gets per wei
  uint256 public cost;  // 0.000015 (first) - 0.000020 (second)
  uint256 public firstICOAmountCounter;
  uint256 public secondICOAmountCounter;
  uint256 public day = 86400; // 1 gün  // mainnetde 30 gün
  uint256 public lastTimeStamp;
  uint256 public icoDayCounter;
  uint256 public transferAmount;
  
  enum CrowdsaleStage {
    FirstICO,
    SecondICO
  }
  CrowdsaleStage public stage = CrowdsaleStage.FirstICO;
  ERC20 public otta;

  constructor(
    address _ottaAddress,
    address _ottaTimelock,
    address _dividend
  ) {
    //require(_rate > 0, "rate must be greater than zero");
    require(_ottaAddress != address(0), "zero address");
    owner = msg.sender;
    ottaAddress = _ottaAddress;
    ottaTimelock = _ottaTimelock;
    dividend = _dividend;
    //cost = 20*10**18; // cost a değer atama *****
    lastTimeStamp = block.timestamp;
    otta = ERC20(ottaAddress);
  }

  //receive() external payable {
    //approve olmalı gönderen*****
  function crowdsale(uint _amountToDai) external {
    //toplam ıco zamanını kontrol et
    require(icoDayCounter <= 2, "finish ico");  // 2 olmalı **********
    uint256 _weiAmount = _amountToDai;
    address _beneficiary = msg.sender;
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    otta.transferFrom(msg.sender, address(this), _weiAmount);//*****
    // calculate token amount to be created
    uint256 _tokens = _weiAmount.div(cost).mul(10**18);
    if (stage == CrowdsaleStage.FirstICO) {
      require(firstICOAmountCounter <= 1750*10**18, "first stage");
      firstICOAmountCounter = firstICOAmountCounter + _tokens;
      otta.transfer(_beneficiary, _tokens);

      emit TokenPurchase(address(this), _beneficiary, _weiAmount, _tokens);
    } else if (stage == CrowdsaleStage.SecondICO) {
      require(secondICOAmountCounter <= 750*10**18, "second stage");
      secondICOAmountCounter = secondICOAmountCounter + _tokens;
      otta.transfer(_beneficiary, _tokens);

      emit TokenPurchase(address(this), _beneficiary, _weiAmount, _tokens);
    }
  }

  function setCost(uint _newCost) public {
    require(msg.sender==owner, "only owner");
    cost = _newCost; //20*10**18
  }

  function performUpkeep(bytes calldata performData) external override {
    // burda iki kontrol yap - hem gün hem de cost 0 dan farklı mı *** cost değişti mi???
    // ilk başta cost sıfır
    require(((block.timestamp - lastTimeStamp) >= day) && (cost!=0), "not epoch");
    lastTimeStamp = block.timestamp;
    icoDayCounter = icoDayCounter + 1;
    if (icoDayCounter == 1) {  // 30 günde bir tetiklenicek
      setCrowdsaleStage(1);
    } else if (icoDayCounter == 2) {
      transferAmount = (address(this).balance).div(8);
      forwardFunds(transferAmount);
    } else if (icoDayCounter > 2) {
        require(address(this).balance != 0, "zero ether");
        forwardFunds(transferAmount);
    }
    performData;
  }

  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    upkeepNeeded = ((block.timestamp - lastTimeStamp) >= day) && (cost!=0);
    performData = checkData;
  }

  /**
   * @dev Allows admin to update the crowdsale stage
   * @param _stage Crowdsale stage
   */
  function setCrowdsaleStage(uint256 _stage) internal {
    if (uint256(CrowdsaleStage.FirstICO) == _stage) {
      stage = CrowdsaleStage.FirstICO;
    } else if (uint256(CrowdsaleStage.SecondICO) == _stage) {
      stage = CrowdsaleStage.SecondICO;
    }

    if (stage == CrowdsaleStage.FirstICO) {
      cost = 20*10**18;
    } else if (stage == CrowdsaleStage.SecondICO) {
      cost = 25*10**18;
    }
  }

  function forwardFunds(uint256 _ethAmount) internal {
    payable(dividend).transfer(_ethAmount);
  }

  function transferOtta(address _account) external {
    require(msg.sender == ottaTimelock, "only otta timelock");
    otta.transfer(_account, otta.balanceOf(address(this)));
  }
}
