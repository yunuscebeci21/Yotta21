// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPrice{

    function getOttaPrice() external returns (uint256);
    function getTaumPrice() external returns (uint256,uint256,uint256);
    function getTtfPrice() external returns (uint256);
    function getLinkPrice() external returns (uint256);
    function getComponentPrice(address componentAddress) external returns(uint256);

}