// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradeComponents{
    /* ================= Events ================= */

    event ComponentBought(address componentAddress, uint256 quantity);
    event ComponentSold(address componentAddress, uint256 quantity);

    /* ================= Functions ================= */
    
    function buyComponents(address _component, uint256 _value, uint256 _wethQuantity) external;
    function redeemTTF() external;
    function residualWeth() external;

}