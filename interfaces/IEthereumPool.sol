// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEthereumPool {
    /*=============== Events ========================*/
    event MintTaumTokenToUser(address _userAddress, uint256 _taumQuantity);
    event SendETHtoLiquidity(address recipient, uint256 _amount);
    event IndexCreated(address payable index, uint256 amount);
    event LimitSetted(uint256 newLimit);
    event OwnerChanged(address newOwner);
    event MinValueChanged(uint256 newMinValue);
    event VaultSetted(address _ethVault);
    event PercentageSetted(bool);
    event GradualSetted(address _gradualReductionAddress);
    event TaumSetted(address _taumTokenAddress);

    receive() external payable;
    function feedVault(uint256 _amount) external returns (bool);
    function _issueQuantity() external view returns (uint256);
}
