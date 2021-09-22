// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEthereumVault{
     /*============ Events ================ */

    event WithDrawtoUser(address userAddress, uint256 price);
    event PoolFeeded(address poolAddress, uint256 quantity);
    event EthPoolSetted(address _ethPool);


    function withdraw(address payable _userAddress, uint256 _withdrawPrice) external returns (bool);
    function feedPool(uint256 _amount) external payable returns (bool);
}