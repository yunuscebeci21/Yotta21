  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pool{
    /* ================= Functions ================= */
    /// @notice This method returns Uni-V2 total supply
    function totalSupply() external view returns (uint);
    /// @notice This method returns Uni-V2 balance 
    function balanceOf(address owner) external view returns (uint);
    /// @notice Reserves token0 and token1 in the pool
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    /// @notice This method returns the pair first token(token0) address
    function token0() external view returns (address);
}