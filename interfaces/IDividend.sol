// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDividend{
    /* ================= Events ================= */

    event OttaTokenLocked(address _userAddress, uint256 _amount);

    /* ================= Functions ================= */
        
    function setEpoch(bool _epoch) external returns(bool,uint256);
    function getDividendRequesting() external;

}