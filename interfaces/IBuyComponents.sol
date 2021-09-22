// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyComponents{
     /* ================= Events ================= */

    event ComponentBought(address componentAddress, uint256 quantity);
    event ComponentSold(address componentAddress, uint256 quantity);
    event EthVaultSetted(address _ethVault);
    event GradualTaumSetted(address _gradualTaum);
    event IndexLiquidityPoolSetted(address _indexPool);
    event EthPoolSetted(address _ethPool);
    
    function buyComponents(address _component, uint256 _value, uint256 _wethQuantity) external;
    function redeemIndex() external;
    function residualWeth() external;

}