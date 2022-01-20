// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Yotta
/// @author Yotta21
/// @notice Dividend token for VC and consultants
contract Yotta is ERC20 {
  
  /*================== State Variables ===================*/
  /// @notice Total supply Yotta
  uint256 public constant TOTAL_SUPPLY_YOTTA = 281600000 * 10 ** 18;

  /*=============== Constructor ========================*/
  constructor(
    string memory name_,
    string memory symbol_,
    address _multiSignWallet
  ) ERC20(name_, symbol_){
    _mint(_multiSignWallet, TOTAL_SUPPLY_YOTTA);
  }
}
