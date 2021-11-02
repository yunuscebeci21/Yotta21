// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISetToken} from "../tokenSet/ISetToken.sol";

interface IEthereumPoolTTFAdapter {
    
    function getRequiredComponents(ISetToken _setToken, uint256 _quantity)
        external
        returns (address[] memory, uint256[] memory);

    function buyTTFComponents(
        address _component,
        uint256 _value,
        uint256 _wethQuantity
    ) external returns (bool);

    function issueTTF() external returns (bool);
}
