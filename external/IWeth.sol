// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeth is IERC20{
    /* ================= Functions ================= */
    /// @notice Converts Ether to Weth
    function deposit() external payable;
    /// @notice Converts Weth to Ether
    function withdraw(uint256 wad) external;
}