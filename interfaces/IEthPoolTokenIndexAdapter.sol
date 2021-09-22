// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

interface IEthPoolTokenIndexAdapter {
    event BuyerAddressChanged(address newAddress);
    event IndexPoolSetted(address _indexPoolAddress);
    event EthPoolSetted(address _ethPoolAddress);
    
    function getRequiredComponents(ISetToken _setToken, uint256 _quantity)
        external
        returns (address[] memory, uint256[] memory);

    function buyIndexComponents(
        address _component,
        uint256 _value,
        uint256 _wethQuantity
    ) external payable returns (bool);

    function issueIndex() external payable returns (bool);
}
