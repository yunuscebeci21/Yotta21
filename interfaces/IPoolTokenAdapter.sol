// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolTokenAdapter{
    event EthVaultSetted(address _ethereumVaultAddress);
    event EthPoolSetted(address _ethereumPoolAddress);
    event PriceSetted(address _priceAddress);
    event TaumSetted(address _taumTokenAddress);

    function returnTaumToken(address recipient, uint256 ethQuantity) external;
    function returnInvestment(address payable recipient, uint256 taumQuantity) external returns(bool);
}