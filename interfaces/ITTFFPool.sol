// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITTFFPool {
    /* ================= Events ================= */
    /// @notice An event thats emitted when sending to UniswapV2Adapter
    event TTFFSent(bool _state);
    
    /* ================= Functions ================= */
    /// @notice This method sends TTFFs to UniswapV2Adapter Contract
    function sendTTFF() external;

    /// @notice Returns ttff address
    function getTTFF() external view returns (address);
}
