// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDividend {
  /* ================= Events ================= */
  /// @notice An event thats emitted when Otta locked for Manager contract
  event OttaTokenLocked(address _userAddress, uint256 _amount);

  /* ================= Functions ================= */
  /// @notice Setting locking epoch
  /// @dev Function that adjusts the entry and exit in the dividend period
  /// @dev For the manager contract, the Otta token amount in LockedOtta 
  /// is written to the map.
  /// @param 'epoch' The state of locking epoch
  function setEpoch(bool _epoch) external returns (bool, uint256);

  /// @notice Calculates dividend amount of Manager contract
  /// @dev Sends dividend to Manager contract
  /// @dev Ether transfer to the manager contract takes place in proportion 
  /// to the amount written to the map for the manager contract.
  function getDividendRequesting() external;

   /// @notice Returns period counter for dividend
  function getPeriod() external view returns (uint256);
  
  /// @notice Calculates dividend amount of account 
  /// @dev Sends dividend as Ether to account 
  function getDividend(address _account) external;

  /// @notice Calculates dividend amount of account 
  /// @dev Sends dividend as Ether and Otta token to account 
  function getDividendAndOttaToken(address _account) external;
}
