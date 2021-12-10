// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradeFromUniswapV2{
    /* ================= Events ================= */
    /// @notice An event thats emitted when buying Components
    event ComponentBought(address componentAddress, uint256 quantity);
    /// @notice An event thats emitted when selling Components
    event ComponentSold(address componentAddress, uint256 quantity);

    /* ================= Functions ================= */
    /// @notice Swaps wrapped ether to needed token on uniswapV2
    function buyComponents(address _component, uint256 _value, uint256 _wethQuantity) external;

    /// @notice Burning ttff and selling components for weth
    /// It sends weth to eth vault
    function redeemTTFF() external;

    /// @notice After buying transfers to residual weth vault
    function residualWeth() external;
}