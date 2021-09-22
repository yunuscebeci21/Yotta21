// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IUniswapV2Adapter{
    event IndexPoolSetted(address _indexLiquidityPoolAddress);
    event GradualSetted(address _gradualAddress);
    event EthVaultSetted(address _ethVault);
    
    function approveTokens() external;
    function addLiquidity() external returns(bool state);
    function removeLiquidity(uint256 _percent) external returns (bool state);
    function bringIndexesFromPool() external returns (bool state);

}