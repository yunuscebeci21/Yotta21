// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ILPTTFF } from "./interfaces/ILPTTFF.sol";
import { IWeth } from "./external/IWeth.sol";
import { IPrice } from "./interfaces/IPrice.sol";
import { IUniswapV2Router02 } from "./external/IUniswapV2Router02.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title LPTTFFTrade
/// @author Yotta21
contract LPTTFFTrade {
  using SafeMath for uint256;
  address public owner;
  address public dividend;
  address public ethPoolAddress;
  address public protocolVaultAddress;
  address public lpTtffAddress;
  address public timelockForOtta;
  address public timelockForMesh;
  ERC20 public lpTtffToken;

  constructor(address _timelockForOtta, address _timelockForMesh, address _dividend, address _lpTtffAddress, address _ethPoolAddress, address _protocolVaultAddress) {
      timelockForOtta = _timelockForOtta;
      timelockForMesh = _timelockForMesh;
      dividend = _dividend;
      lpTtffAddress = _lpTtffAddress;
      ethPoolAddress = _ethPoolAddress;
      protocolVaultAddress = _protocolVaultAddress;
      lpTtffToken = ERC20(_lpTtffAddress);
  }

  receive() external payable {
      if(msg.sender == protocolVaultAddress){
        payable(dividend).transfer(msg.value);
      }
      else{
        payable(ethPoolAddress).transfer(msg.value);
      }   
  }
  
  function sellLPTTFF(uint256 _lpTtffAmount) external {
    require(msg.sender == timelockForOtta || msg.sender == timelockForMesh, "only otta timelock or mesh timelock");
    (bool success,) = lpTtffAddress.delegatecall(
            abi.encodeWithSignature("receiver(uint256)", _lpTtffAmount));
    require(success, "lpTtff sell fail");    
  }

}
