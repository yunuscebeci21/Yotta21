// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ILPTTFF } from "./interfaces/ILPTTFF.sol";
import { ILPTrade } from "./interfaces/ILPTrade.sol";
import { IWeth } from "./external/IWeth.sol";
import { IPrice } from "./interfaces/IPrice.sol";
import { IUniswapV2Router02 } from "./external/IUniswapV2Router02.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title LPTTFFTrade
/// @author Yotta21
contract LPTTFFTrade is ILPTrade{
  using SafeMath for uint256;
  address public owner;
  address public dividend;
  address public ethPoolAddress;
  address public protocolVaultAddress;
  address public lpTtffAddress;
  address public timelockForOtta;
  address public timelockForMesh;
  ERC20 public lpTtffToken;
  ERC20 public weth;
  uint256 public constant MAX_INT = 2**256 - 1;

  constructor(address _timelockForOtta, address _timelockForMesh, address _dividend, address _lpTtffAddress, address _ethPoolAddress, address _protocolVaultAddress, address _wethAddress) {
      timelockForOtta = _timelockForOtta;
      timelockForMesh = _timelockForMesh;
      dividend = _dividend;
      lpTtffAddress = _lpTtffAddress;
      ethPoolAddress = _ethPoolAddress;
      protocolVaultAddress = _protocolVaultAddress;
      lpTtffToken = ERC20(_lpTtffAddress);
      weth = ERC20(_wethAddress);
  }

  /*receive() external payable {
      if(msg.sender == protocolVaultAddress){
        payable(dividend).transfer(msg.value);
      }
      else{
        payable(ethPoolAddress).transfer(msg.value);
      }   
  }*/

  function trade() external {
    if(msg.sender == dividend){
        weth.transfer(ethPoolAddress, weth.balanceOf(address(this)));
      }
    else{
        weth.transfer(dividend, weth.balanceOf(address(this)));
    }   
  }


  function approveLPTtff() public {
    lpTtffToken.approve(lpTtffAddress,MAX_INT);
  }
  
  function sellLPTTFF(uint256 _lpTtffAmount) external {
    require(msg.sender == timelockForOtta || msg.sender == timelockForMesh, "only otta timelock or mesh timelock");
    //lpTtffToken.transferFrom(address(this), protocolVaultAddress, _lpTtffAmount);
    (bool success,) = lpTtffAddress.delegatecall(
            abi.encodeWithSignature("receiver(uint256)", _lpTtffAmount));
    require(success, "lpTtff sell fail");    
  }

}
