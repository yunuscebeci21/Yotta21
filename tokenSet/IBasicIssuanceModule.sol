// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

interface IBasicIssuanceModule {
    /* ================= Functions ================= */
    /// @notice TTFF issue transaction
    function issue(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external;
    
    /// @notice TTFF redeem transaction
    function redeem(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external;
    
    /// @notice Brings components in TTFF
    function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    ) external returns (address[] memory, uint256[] memory);
}
