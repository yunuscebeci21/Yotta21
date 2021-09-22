// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IOttaToken {
   /*=============== Events ========================*/
    event OttaTokenPurchased(
        address indexed beneficiary,
        uint256 amount
    );
    event WalletContractSetted(address _walletContractAddress);
    event PriceSetted(address _priceAddress);

}