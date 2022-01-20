// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVCADVTeam {
  /* ================= Events ================= */
  /// @notice An event thats emitted when Otta locked for Manager contract
  event OttaTokenLocked(address _userAddress, uint256 _amount);

  /* ================= Functions ================= */
  /// @notice Setting locking epoch
  /// @param 'epoch' The state of locking epoch
  function setEpochForVCDividend(bool _epoch) external returns (bool, uint256);

  /// @notice Calculates Yotta dividend amount of account 
  /// @dev Sends Yotta dividend as Ether to account
  function getDividendYotta(address _account) external;

  /// @notice Calculates dividend amount of account 
  /// @dev Sends dividend as Ether and Yotta token to account 
  function getDividendAndYottaToken(address _account) external;
}
