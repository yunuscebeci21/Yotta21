// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEthereumPool {
    /*=============== Events ========================*/

    event MintTaumTokenToUser(address _userAddress, uint256 _taumQuantity);
    event SendWETHtoLiquidity(address _recipient, uint256 _amount);
    event TTFCreated(address _ttf, uint256 _amount);

    /*=============== Functions ========================*/
    function feedVault(uint256 _amount) external returns (bool);
    function _issueQuantity() external view returns (uint256);
    function addLimit(uint256 _limit) external;
}
