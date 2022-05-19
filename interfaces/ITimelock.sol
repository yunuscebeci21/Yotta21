// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITimelock{
   function getGuardianWallet() external view returns(address);
   function getTokenAddress() external view returns(address);
}



