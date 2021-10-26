// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolGradual {
    /*=============== Events ========================*/
    // The transfer event to vault
    event TransferToVault(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );
    // The transfer event to eth pool
    event TransferToETHPool(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );


}
