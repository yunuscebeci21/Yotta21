// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeepRegistry {
    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber
        );

    function getMinBalanceForUpkeep(uint256 id)
        external
        view
        returns (uint96 minBalance);

    function addFunds(uint256 id, uint96 amount) external;
}