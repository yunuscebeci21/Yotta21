// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IUniswapV2Router02 } from "../external/IUniswapV2Router02.sol";

contract TreasuryVester {

  /*********************** otta satış alış fonksiyonu yazılacak****************************** */
  using SafeMath for uint256;

  address public otta;
  address public recipient; // otta timelock
  address public swapRouterAddress;

  uint256 public constant DEADLINE = 5 hours;
  uint256 public constant MAX_INT = 2**256 - 1;
  uint256 public vestingAmount;
  uint256 public vestingBegin;
  uint256 public vestingCliff;
  uint256 public vestingEnd;

  uint256 public lastUpdate;

  IUniswapV2Router02 public swapRouter;

  constructor(
    address otta_,
    address recipient_,
    address swapRouter_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingCliff_, 
    uint256 vestingEnd_
  ) {
    require(
      vestingBegin_ >= block.timestamp,
      "TreasuryVester::constructor: vesting begin too early"
    );
    require(
      vestingCliff_ >= vestingBegin_,
      "TreasuryVester::constructor: cliff is too early"
    );
    require(
      vestingEnd_ > vestingCliff_,
      "TreasuryVester::constructor: end is too early"
    );

    otta = otta_;
    recipient = recipient_;
    swapRouter = IUniswapV2Router02(swapRouter_);

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingCliff = vestingCliff_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin;
  }

  function claim() public {
    require(
      block.timestamp >= vestingCliff,
      "TreasuryVester::claim: not time yet"
    );
    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = IOtta(otta).balanceOf(address(this));
    } else {
      amount = vestingAmount.mul(block.timestamp - lastUpdate).div(
        vestingEnd - vestingBegin
      );
      lastUpdate = block.timestamp;
    }
    IOtta(otta).transfer(recipient, amount);
  }
  
  /* otta nın şu yüzdesini sat mı yoksa otta nın şu miktarını sat???????????? */
  function sellToToken(uint256 _amount, address _sellToken, address _buyToken) external {
    require(msg.sender == recipient, "only otta timelock");
    //uint256 _amount = ottaToken.balanceOf(address(this)).mul(_percentage).div(100);
    approveComponents(_sellToken, _buyToken);
    sell(_amount, _sellToken, _buyToken);
  }

  function approveComponents(address _sellToken, address _buyToken) internal {
    // sell ve buy için allowance kontrolü yap!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ERC20 buyToken = ERC20(_buyToken);
    ERC20 sellToken = ERC20(_sellToken);
    
    //if(_allowances[swapRouterAddress][buyToken] == 0){
      buyToken.approve(swapRouterAddress, MAX_INT);
    //}
    //if(_allowances[swapRouterAddress][sellToken] == 0){
      sellToken.approve(swapRouterAddress, MAX_INT);
    //}
  }

   function sell(uint256 _amount, address _sellToken, address _buyToken) internal {
    address[] memory _path = new address[](2);
    _path[0] = _sellToken;
    _path[1] = _buyToken;
    swapRouter.swapExactTokensForTokens(
      _amount,
      0,
      _path,
      address(this),
      block.timestamp + DEADLINE
    );
  }

}

interface IOtta {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address dst, uint256 rawAmount) external returns (bool);
}
