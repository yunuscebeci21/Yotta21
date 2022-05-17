// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGroups {
    function setEpochForGroupsDividend(bool _epoch) external returns (bool, uint256);
    function getDividend(address _account, string memory _groupName) external;
    //function setGroupStatus(string memory _groupName, bool _status) external;
    function setGroupAddress(string memory _groupName, address _groupAddress) external;
    //function setGroupPercentage(string memory _groupName, uint256 _groupPercentage) external;
    function addGroup(string memory _groupName, address _groupAddress/*, uint256 _groupPercentage*/) external;
}