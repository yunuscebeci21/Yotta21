// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaum {
   /*============ Functions ================ */
   /// @notice Function to call before _mint functions
   /// @dev Can only call EthereumPool contract
   function tokenMint(address _recipient, uint256 _amount) external;
}