// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Adapter{

    function addLiquidity() external returns(bool _state);
    function removeLiquidity(uint256 _percent) external returns (bool _state);
    function bringTTFsFromPool() external returns (bool _state);

}