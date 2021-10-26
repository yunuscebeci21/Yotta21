// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrice{

    function getOttaPrice() external returns (uint256);
    function getTaumPrice(uint256 _ethAmount) external returns (uint256,uint256,uint256);
    function getTtfPrice() external returns (uint256);
    function getLinkPrice() external returns (uint256);
    function getComponentPrice(address _componentAddress) external returns(uint256);

}