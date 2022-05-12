// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOtta {
    function getIsDiscount(address) external view returns (bool);
}