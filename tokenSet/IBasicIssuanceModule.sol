// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    ISetToken
} from "../tokenSet/ISetToken.sol";

interface IBasicIssuanceModule {
    function issue(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function redeem(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    ) external returns (address[] memory, uint256[] memory);
}
