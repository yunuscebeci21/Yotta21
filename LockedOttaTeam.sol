// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title LockedOttaTeam
/// @author Yotta21
contract LockedOttaTeam{
  /* ================ Events ================== */
  /// @notice An event thats emitted when Otta contract address setting
  event OttaSetted(address _ottaAddress);

  /* ================ State Variables ================== */
  /// @notice Importing otta token methods
  ERC20 private ottaToken;

  /* ================ Constructor ================== */
  constructor(address _ottaAddress) {
    require(_ottaAddress != address(0), "Zero address");
    ottaToken = ERC20(_ottaAddress);
  }

  /* ================ Functions ================== */

  /// @notice Returning otta balance of this contract
  function getOttaAmount() public view returns (uint256) {
    uint256 _ottaAmount = ottaToken.balanceOf(address(this));
    return _ottaAmount;
  }
}
