// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ISetToken} from "../tokenSet/ISetToken.sol";

interface IStreamingFeeModule{
    function accrueFee(ISetToken _setToken) external;
}