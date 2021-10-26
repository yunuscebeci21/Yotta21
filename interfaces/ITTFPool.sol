// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITTFPool {
    event TTFSent(bool _state);

    function sendTTF() external;
    function getTTF() external view returns (address);
}
