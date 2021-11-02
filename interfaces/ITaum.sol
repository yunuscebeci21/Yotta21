// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ITaum is IERC20 {
   function tokenMint(address recipient, uint256 amount) external;
}