// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrentVotes{
    function getCurrentVotes(address account) external view returns (uint256);
}