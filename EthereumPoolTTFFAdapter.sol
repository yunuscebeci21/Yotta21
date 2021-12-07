// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { IBasicIssuanceModule } from "./tokenSet/IBasicIssuanceModule.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IEthereumPoolTTFFAdapter } from "./interfaces/IEthereumPoolTTFFAdapter.sol";
import { ITradeFromUniswapV2 } from "./interfaces/ITradeFromUniswapV2.sol";
import { IEthereumPool } from "./interfaces/IEthereumPool.sol";
import { ITTFFPool } from "./interfaces/ITTFFPool.sol";

/// @title EthereumPoolTTFAdapter
/// @author Yotta21
/// @notice TTFF issue takes place
contract EthereumPoolTTFFAdapter is IEthereumPoolTTFFAdapter {
  /* ================= Events ================= */
  /// @notice An event thats emitted when TradeFromUniswapV2 contract setting
  event TradeFromUniswapV2Setted(address _tradeFromUniswapV2Address);
  /// @notice An event thats emitted when TTFFPool contract setting
  event TTFFPoolSetted(address _ttfPoolAddress);
  /// @notice An event thats emitted when EthereumPool contract setting
  event EthPoolSetted(address _ethPoolAddress);

  /* ================= State Variables ================= */

  /// @notice Address of Wrapped Ether
  address private wethAddress;
  /// @notice Address of ttff pool
  address public ttffPoolAddress;
  /// @notice Address of Ethereum pool
  address payable public ethPoolAddress;
  /// @notice Address of owner
  address public owner;
  /// @notice Address of issuance module
  address public issuanceModuleAddress;
  /// @notice Address of tradefromuniswap
  address public tradeFromUniswapV2Address;
  /// @notice Maximum size of uint256
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice Set states of this contracts
  bool public isTradeFromUniswapV2;
  bool public isTtffPoolSetted;
  bool public isEthPoolSetted;
  /// @notice Importing Ethereum pool methods
  IEthereumPool public ethPool;
  /// @notice Importing ttff pool methods
  ITTFFPool public ttffPool;
  /// @notice Importing Component buyer methods
  ITradeFromUniswapV2 public trade;
  /// @notice Importing issuance module methods
  IBasicIssuanceModule public issuanceModule;

  /* ================= Modifiers ================= */
  /// @notice Throws if the sender is not owner
  modifier onlyOwner() {
    require(msg.sender == owner, "Only Owner");
    _;
  }

  /// @notice Throws if the sender is not eth pool
  modifier onlyEthPool() {
    require(msg.sender == ethPoolAddress, "Only Ether Pool");
    _;
  }

  /* ================= Constructor ================= */
  constructor(address _wethAddress, address _issuanceModuleAddress) {
    owner = msg.sender;
    require(_wethAddress != address(0), "zero address");
    wethAddress = _wethAddress;
    require(_issuanceModuleAddress != address(0), "zero address");
    issuanceModuleAddress = _issuanceModuleAddress;
    issuanceModule = IBasicIssuanceModule(issuanceModuleAddress);
  }

  /* =================  Functions ================= */
  /* ================= External Functions ================= */
  /// @notice Up to MAX_INT, issuanceModule address is approved to components in ttff
  function approveComponents() external onlyOwner {
    address _ttffAddress = ttffPool.getTTFF();
    ISetToken _ttff = ISetToken(_ttffAddress);
    address[] memory _components = _ttff.getComponents();
    for (uint256 j = 0; j < _components.length; j++) {
      ERC20 _component = ERC20(_components[j]);
      _component.approve(issuanceModuleAddress, MAX_INT);
    }
  }
  
  /// @inheritdoc IEthereumPoolTTFFAdapter
  function getRequiredComponents(ISetToken _ttf, uint256 _quantity)
    external
    override
    onlyEthPool
    returns (address[] memory, uint256[] memory)
  {
    (address[] memory _components, uint256[] memory _values) = issuanceModule
      .getRequiredComponentUnitsForIssue(_ttf, _quantity);
    return (_components, _values);
  }
   
  /// @inheritdoc IEthereumPoolTTFFAdapter
  function buyTTFFComponents(
    address _component,
    uint256 _value,
    uint256 _wethQuantity
  ) external override onlyEthPool returns (bool) {
    trade.buyComponents(_component, _value, _wethQuantity);
    return true;
  }

  /// @inheritdoc IEthereumPoolTTFFAdapter
  function issueTTFF() external override onlyEthPool returns (bool) {
    address _ttffAddress = ttffPool.getTTFF();
    ISetToken _ttff = ISetToken(_ttffAddress);
    uint256 _quantity = ethPool._issueQuantity();
    issuanceModule.issue(_ttff, _quantity, ttffPoolAddress);
    return (true);
  }

  /* ================= Public Functions ================= */
  /// @notice Setting trade address only once
  /// @param _tradeFromUniswapV2Address Address of TradeFromUniswapV2
  function setTradeFromUniswapV2(address _tradeFromUniswapV2Address)
    public
    onlyOwner
    returns (address)
  {
    require(!isTradeFromUniswapV2, "Already setted");
    require(_tradeFromUniswapV2Address != address(0), "zero address");
    isTradeFromUniswapV2 = true;
    tradeFromUniswapV2Address = _tradeFromUniswapV2Address;
    trade = ITradeFromUniswapV2(tradeFromUniswapV2Address);
    emit TradeFromUniswapV2Setted(tradeFromUniswapV2Address);
    return tradeFromUniswapV2Address;
  }

  /// @notice Setting ttff pool address and importing methods
  /// @param _ttffPoolAddress Address of ttff pool
  function setTTFPool(address _ttffPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isTtffPoolSetted, "Already setted");
    require(_ttffPoolAddress != address(0), "zero address");
    isTtffPoolSetted = true;
    ttffPoolAddress = _ttffPoolAddress;
    ttffPool = ITTFFPool(ttffPoolAddress);
    emit TTFFPoolSetted(ttffPoolAddress);
    return (ttffPoolAddress);
  }

  /// @notice Setting ethereum pool address and importing methods
  /// @param _ethPoolAddress Address of ethereum pool
  function setEthPool(address payable _ethPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isEthPoolSetted, "Already Setted");
    require(_ethPoolAddress != address(0), "zero address");
    isEthPoolSetted = true;
    ethPoolAddress = _ethPoolAddress;
    ethPool = IEthereumPool(ethPoolAddress);
    emit EthPoolSetted(ethPoolAddress);
    return (ethPoolAddress);
  }
}
