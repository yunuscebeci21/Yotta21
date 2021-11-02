// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title LockedOtta
/// @author Yotta21

contract LockedOtta {
    /* ================ Events ================== */

    event OttaSetted(address _ottaAddress);

    /* ================ State Variables ================== */

    // address of contract creater
    address public owner;
    // set status of this contract
    bool public isOttaSetted;
    // importing otta token methods
    ERC20 private ottaToken;

    /* ================ Constructor ================== */

    constructor() {
        owner = msg.sender;
    }

    /* ================ Functions ================== */
    /* ================ Public Functions ================== */

    /*
     * Notice: Setting otta contract address
     * Param:
     * '_ottaAddress' address of otta contract address
     */
    function setOtta(address _ottaAddress) public returns (address) {
        require(msg.sender == owner, "Only Owner");
        require(!isOttaSetted, "Already setted");
        require(_ottaAddress != address(0), "zero address");
        isOttaSetted = true;
        ottaToken = ERC20(_ottaAddress);
        emit OttaSetted(_ottaAddress);
        return _ottaAddress;
    }

    /*
     * Notice: Returning otta balance of this contract     
     */
    function getOttaAmount() public view returns(uint256){
        uint256 _ottaAmount = ottaToken.balanceOf(address(this));
        return _ottaAmount;
    }
    
}
