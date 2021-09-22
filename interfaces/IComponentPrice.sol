// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComponentPrice{

    event FeeSetted(uint256 _fee);
    event JobIdSetted(bytes32 _jobId);
    event OracleSetted(address _oracle);
    event TotalCounterSetted(uint256 _totalCounter);
    function requestComponentsPrice() external;
    function componentPrice(address _component) external view returns(uint256);
}