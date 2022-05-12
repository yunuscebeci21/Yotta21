// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockedOttaMesh {
    function getMeshPercentage(string memory) external view returns (uint256);
}


