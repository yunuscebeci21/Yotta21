// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIndexLiquidityPool {
    event IndexesSetted(address[] _indexes);
    event IndexSent(bool _state);

    function sendIndex() external;
    function getIndex() external view returns (address);
}
