// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrice{
    /*=============== Functions ========================*/
    /// @notice Otta price calculate from UniswapV2
    function getOttaPrice() external returns (uint256);

    /// @notice Taum price calculate with the amount of ether in the Protocol
    function getTaumPrice(uint256 _ethAmount) external returns (uint256,uint256,uint256);
    
    /// @notice TTFF price calculate from UniswapV2
    function getTtffPrice() external returns (uint256);
     
    /// @notice Component prices calculate from UniswapV2
    function getComponentPrice(address _componentAddress) external returns(uint256);
}