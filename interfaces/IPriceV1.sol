// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceV1{
    function getYotta21Price() external view returns (uint256);
    function getTaumPrice() external returns (uint256);
    function prices(address _indexAddress) external returns (uint256);
    function getLinkPrice() external view returns (uint256);
    
}