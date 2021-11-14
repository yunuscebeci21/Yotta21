// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV2Adapter} from "./interfaces/IUniswapV2Adapter.sol";
import {ITTFPool} from "./interfaces/ITTFPool.sol";
import {IStreamingFeeModule} from "./tokenSet/IStreamingFeeModule.sol";
import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title TTFPool
/// @author Yotta21

contract TTFPool is ITTFPool, KeeperCompatibleInterface{

    /*================== Events ===================*/


    /*================== State Variables ===================*/

    // Address of the addLiquidityAdapter (Caller of Uniswap or others)
    address public uniswapV2AdapterAddress;
    // Address of the TradeFromUniswapV2
    address public tradeFromUniswapV2Address;
    // address of contract creater
    address public owner;
    // address of manager
    address public manager;
    // Addresses  of ttf token
    address public ttfAddress;
    // Chainlink keeper call time
    uint256 public immutable interval;
    // Chainlink keeper trigger last time
    uint256 public lastTimeStamp;
    // Accrue streaming fee from tokenSet
    IStreamingFeeModule private streamingFee;

    /* ================= Modifiers ================= */

    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /*===================== Constructor ======================*/
    constructor(
        address _manager,
        uint256 _interval,
        address _uniswapV2Adapter,
        address _tradeFromUniswapV2Address,
        address _ttfAddress,
        address _streamingFeeModule
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        interval = _interval;
        require(_uniswapV2Adapter != address(0), "zero address");
        uniswapV2AdapterAddress = _uniswapV2Adapter;
        require(_tradeFromUniswapV2Address != address(0), "zero address");
        tradeFromUniswapV2Address = _tradeFromUniswapV2Address;
        require(_ttfAddress != address(0), "zero address");
        ttfAddress = _ttfAddress;
        require(_streamingFeeModule != address(0), "zero address");
        streamingFee = IStreamingFeeModule(_streamingFeeModule);
    }

    /* ================== Functions ================== */
    /* ================== Public Functions ================== */

    /* Notice: Setting manager address methods
     * Params:
     * '_manager' The manager address.
     */
    /*function setManager(address _manager) public onlyOwner returns (address) {
        require(_manager != address(0), "zero address");
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }*/

    /* ================== External Functions ================== */
    /*
     * Notice: This method sends Indexes to UniswapAdapter Contract
     */
    function sendTTF() external override {
        require(
            (msg.sender == uniswapV2AdapterAddress || msg.sender == tradeFromUniswapV2Address),
            "only protocol"
        );
        ERC20 _ttf = ERC20(ttfAddress);
        bool success = _ttf.transfer(msg.sender, _ttf.balanceOf(address(this)));
        require(success, "Transfer Failed");
        emit TTFSent(true);
    }

    /*
     * Notice: Returns ttf address
     */
    function getTTF() external view override returns (address) {
        return ttfAddress;
    }

    /*
     * Notice: Checking the upkeepNeeded condition
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    /*
     * Notice: Chainlink Keeper method calls unlocked method
     */
    function performUpkeep(bytes calldata performData) external override{
        require((block.timestamp - lastTimeStamp) > interval, "not epoch");
        lastTimeStamp = block.timestamp;
        collectStreamingFee();
        performData;
    }

    /*================== Internal Functions =====================*/

    /*
     * Notice: Collecting TTF streaming fee
     */
    function collectStreamingFee() internal {
        ISetToken _ttf = ISetToken(ttfAddress);
        streamingFee.accrueFee(_ttf);
    }

    
}
