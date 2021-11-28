// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Adapter{
    /* ================= Functions ================= */
    /// @notice It is added to the UniiswapV2 pool as 50% ttff and 50% weth.
    /// @dev If weth remains, it will be transferred to the protocol vault.
    /// @dev If the remaining ttff is transferred to the ttff pool.
    function addLiquidity() external returns(bool _state);
    
    /// @notice It is withdrawn from the UniswapV2 pool at the entered percentage.
    /// @dev Ttff is transferred to TTFFPool.
    /// @dev The weth protocol is transferred to the ProtocolVault.
    function removeLiquidity(uint256 _percent) external returns (bool _state);

    /// @notice Ttff transfers to this contract to add to UniswapV2 pool
    function bringTTFFsFromPool() external returns (bool _state);

}