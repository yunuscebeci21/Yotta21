// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IUniswapAdapter{
    event IndexPoolSetted(address _indexLiquidityPoolAddress);
    event GradualSetted(address _gradualAddress);
    event TokenIdsSetted(bool _state);
    event EthVaultSetted(address _ethVault);
    event EthPoolSetted(address _ethPoolAddress);
    
    function approveTokens() external;
    function addLiquidityToUni() external payable returns(bool state);
    function collectFromUni() external returns (bool state);
    function bringIndexesFromPool() external returns (bool state);
    function decreaseCollect(uint128 _liquidityPercentage) external returns(bool state);

}
