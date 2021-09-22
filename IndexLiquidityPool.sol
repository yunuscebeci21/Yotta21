// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Adapter.sol";
import {IIndexLiquidityPool} from "./interfaces/IIndexLiquidityPool.sol";

/// @title Index Liquidity Pool
/// @author Yotta21

contract IndexLiquidityPool is IIndexLiquidityPool {

    /*================== State Variables ===================*/
    // Address of the addLiquidityAdapter (Caller of Uniswap or others)
    address public uniswapV2AdapterAddress;
    // Address of the Buyer
    address public buyer;
    // address of contract creater
    address public owner;
    // address of manager
    address public manager;
    // Addresses  of indexes
    address public ttfAddress;
    // set state of indexes
    //bool private isIndexesSetted = false;

    /* ================= Modifiers ================= */

    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /*===================== Constructor ======================*/
    constructor(address _manager, address _uniswapV2Adapter,address _buyer, address _ttfAddress) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_uniswapV2Adapter != address(0),"zero address");
        uniswapV2AdapterAddress = _uniswapV2Adapter;
        require(_buyer != address(0),"zero address");
        buyer = _buyer;
        require(_ttfAddress != address(0),"zero address");
        ttfAddress = _ttfAddress;
    }

    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }
    function setBuyer(address _buyer)
        public
        onlyOwner
        returns (address buyerAddress)
    {
        buyer = _buyer;
        return (buyer);
    }

    /* ================== External Functions ================== */
    /*
     * Notice: This method sends Indexes to UniswapAdapter Contract
     */
    function sendIndex() external override{
        require((msg.sender == uniswapV2AdapterAddress || msg.sender== buyer),"only protocol");
        ERC20 ttf = ERC20(ttfAddress);
        bool success = ttf.transfer(msg.sender, ttf.balanceOf(address(this)));
        require(success, "Transfer Failed");
        emit IndexSent(true);
    }

    /*
     * Notice: Returns indexes
     */
    function getIndex()
        external
        view
        override
        returns (address _ttfAddress)
    {
        return ttfAddress;
    }
}
