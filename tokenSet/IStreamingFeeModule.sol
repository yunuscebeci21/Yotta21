// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

interface IStreamingFeeModule{
    /* ================= Functions ================= */
    /// @notice Gets TTFF fee with StreamingFee Module.
    function accrueFee(ISetToken _setToken) external;
}