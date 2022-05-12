// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMeshNFTDividend{
    function setEpochForMeshNFTDividend(bool _epoch) external returns (bool, uint256);
    function getDividend(address _account, uint _id) external;
}