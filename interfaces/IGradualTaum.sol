// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGradualTaum {
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
    // Vault set event
    event VaultSetted(address _ethVaultAddress);
    // current percent event
    event CurrentPercent(uint256 _currentPercent);
    event EthPoolSetted(address _ethPoolAddress);

}
