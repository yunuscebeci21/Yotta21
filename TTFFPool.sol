// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IUniswapV2Adapter } from "./interfaces/IUniswapV2Adapter.sol";
import { ITTFFPool } from "./interfaces/ITTFFPool.sol";
import { IStreamingFeeModule } from "./tokenSet/IStreamingFeeModule.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title TTFPool
/// @author Yotta21

contract TTFFPool is ITTFFPool, KeeperCompatibleInterface {
  /*================== State Variables ===================*/
  /// @notice Address of the addLiquidityAdapter (Caller of Uniswap or others)
  address public uniswapV2AdapterAddress;
  /// @notice Address of the TradeFromUniswapV2
  address public tradeFromUniswapV2Address;
  /// @notice Address of contract creater
  address public owner;
  /// @notice Addresses  of ttff token
  address public ttffAddress;
  /// @notice Chainlink keeper call time
  uint256 public immutable interval;
  /// @notice Chainlink keeper trigger last time
  uint256 public lastTimeStamp;
  /// @notice Accrue streaming fee from tokenSet
  IStreamingFeeModule private streamingFee;

  /*===================== Constructor ======================*/
  constructor(
    uint256 _interval,
    address _uniswapV2Adapter,
    address _tradeFromUniswapV2Address,
    address _ttffAddress,
    address _streamingFeeModule
  ) {
    owner = msg.sender;
    interval = _interval;
    require(_uniswapV2Adapter != address(0), "zero address");
    uniswapV2AdapterAddress = _uniswapV2Adapter;
    require(_tradeFromUniswapV2Address != address(0), "zero address");
    tradeFromUniswapV2Address = _tradeFromUniswapV2Address;
    require(_ttffAddress != address(0), "zero address");
    ttffAddress = _ttffAddress;
    require(_streamingFeeModule != address(0), "zero address");
    streamingFee = IStreamingFeeModule(_streamingFeeModule);
  }

  /* ================== Functions ================== */
  /* ================== External Functions ================== */
  /// @inheritdoc ITTFFPool
  function sendTTFF() external override {
    require(
      (msg.sender == uniswapV2AdapterAddress ||
        msg.sender == tradeFromUniswapV2Address),
      "only protocol"
    );
    ERC20 _ttff = ERC20(ttffAddress);
    bool success = _ttff.transfer(msg.sender, _ttff.balanceOf(address(this)));
    require(success, "Transfer Failed");
    emit TTFFSent(true);
  }

  /// @inheritdoc ITTFFPool
  function getTTFF() external view override returns (address) {
    return ttffAddress;
  }

  /// @notice Chainlink Keeper method calls unlocked method
  function performUpkeep(bytes calldata performData) external override {
    require((block.timestamp - lastTimeStamp) > interval, "not epoch");
    lastTimeStamp = block.timestamp;
    collectStreamingFee();
    performData;
  }

  /// @notice Checking the upkeepNeeded condition
  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    performData = checkData;
  }

  /*================== Internal Functions =====================*/
  /// @notice Collecting TTF streaming fee
  function collectStreamingFee() internal {
    ISetToken _ttff = ISetToken(ttffAddress);
    streamingFee.accrueFee(_ttff);
  }
}
