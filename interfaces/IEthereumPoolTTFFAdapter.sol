// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

interface IEthereumPoolTTFFAdapter {
    /*=============== Functions ========================*/
    /// @notice Getter method of required components for create index
    /// @param _setToken Address of TTFF. Must be inherit from ISetToken
    /// @param _quantity quantity of TTFF to issue 
    /// @return Array of component addresses and array of required quantity
    function getRequiredComponents(ISetToken _setToken, uint256 _quantity)
        external
        returns (address[] memory, uint256[] memory);

    /// @notice It buys components
    /// @param _component Address of component to buy
    /// @param _value Quantity of component to buy
    /// @param _wethQuantity Quantity of wrapped ether to swap with component
    function buyTTFFComponents(
        address _component,
        uint256 _value,
        uint256 _wethQuantity
    ) external returns (bool);
    
    /// @notice Minting ttff to ttff pool
    function issueTTFF() external returns (bool);
}
