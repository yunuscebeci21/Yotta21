// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReward{
    event OttaTokenSetted(address _ottaTokenAddress);
    event OttaTokenLocked(address _userAddress, uint256 _amount);
    event WalletContractSetted(address _walletContractAddress);
        
    function setEpoch(bool epoch) external  returns(bool,uint256);

}