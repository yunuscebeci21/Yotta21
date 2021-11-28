// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolVault{
    /*============ Events ================ */
    /// @notice An event thats emitted when the user sells Taum
    event WithDrawtoUser(address userAddress, uint256 price);
    /// @notice An event thats emitted when transferred from ProtocolVault to EthereumPool
    event PoolFeeded(address poolAddress, uint256 quantity);

    /*============ Functions ================ */
    /// @notice It will send calculated withdrawal quantity of ETH to user
    /// @dev This method can callable from Taum contract 
    /// @param _userAddress The user address
    /// @param _withdrawAmount The amount of withdraw
    function withdraw(address payable _userAddress, uint256 _withdrawAmount) external returns (bool);

    /// @notice It transfers Ether from ProtocolVault to EthereumPool.
    /// @dev It is triggers by ProtocolGradual contract
    /// @param _amount The amount to be transferred
    function feedPool(uint256 _amount) external returns (bool);
}