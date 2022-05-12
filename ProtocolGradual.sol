// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IEthereumPool } from "./interfaces/IEthereumPool.sol";
import { ITTFFPool } from "./interfaces/ITTFFPool.sol";
import { IProtocolVault } from "./interfaces/IProtocolVault.sol";
import { IUniswapV2Adapter } from "./interfaces/IUniswapV2Adapter.sol";
import { ITradeFromUniswapV2 } from "./interfaces/ITradeFromUniswapV2.sol";
import { IWeth } from "./external/IWeth.sol";
import { IPrice } from "./interfaces/IPrice.sol";
import { IUniswapV2Pool } from "./external/IUniswapV2Pool.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract ProtocolGradual is KeeperCompatibleInterface {
  using SafeMath for uint256;

  /*================== Events ===================*/
  /// @notice An event thats emitted when EthereumPool contract address setting
  event EthPoolSetted(address _ethPoolAddress);
  /// @notice An event thats emitted when Price contract address setting
  event PriceSetted(address _priceAddress);
  /// @notice An event thats emitted when transfer to ProtocolVault
  event TransferToVault(
    address indexed _from,
    address indexed _to,
    uint256 _amount
  );
  /// @notice An event thats emitted when transfer to EthereumPool
  event TransferToETHPool(
    address indexed _from,
    address indexed _to,
    uint256 _amount
  );

  /*================== State Variables ===================*/
  /// @notice Address of owner
  address public owner;
  /// @notice Address of ethereum pool contract
  address public ethPoolAddress;
  /// @notice Address of ttff pool contract
  address public ttffPoolAddress;
  /// @notice Address of ethereum vault contract
  address public protocolVaultAddress;
  /// @notice Address of uniswap adapter
  address public uniswapV2AdapterAddress;
  /// @notice Address of ERC20 weth
  address public wethAddress;
  /// @notice Address of ttff uniV2
  address public ttffUniPool;
  /// @notice Address of ttff
  address public ttff;
  /// @notice Constant value1
  uint256 public value1;
  /// @notice Constant value2
  uint256 public value2;
  /// @notice Constant value3
  uint256 public value3;
  /// @notice Constant value4
  uint256 public value4;
  /// @notice Percentage of vault in protocol
  uint256 public protocolVaultPercentage;
  /// @notice Percentage for processValue1ToValue2 fonction
  uint256 public removePercentage1;
  /// @notice Percentage for processValue2ToValue3 fonction
  uint256 public removePercentage2;
  /// @notice Set status of this contract
  bool public isEthPoolSetted;
  bool public isPriceSetted;
  /// @notice Importing trade methods
  ITradeFromUniswapV2 public trade;
  /// @notice Importing UniswapV2Adapter methods
  IUniswapV2Adapter public uniV2Adapter;
  /// @notice Importing ProtocolVault methods
  IProtocolVault public protocolVault;
  /// @notice Importing EthereumPool methods
  IEthereumPool public ethPool;
  /// @notice Importing TTFFPool methods
  ITTFFPool public ttffPool;
  /// @notice Importing Price methods
  IPrice public price;
  /// @notice Importing weth methods
  IWeth public weth;

  /*================= Modifiers =================*/
  /// @notice Throws if the sender is not owner
  modifier onlyOwner() {
    require(msg.sender == owner, "Only Owner");
    _;
  }

  /*=============== Constructor ========================*/
  constructor(
    address _protocolVaultAddress,
    address _ttffPoolAddress,
    address _uniswapV2AdapterAddress,
    address _tradeAddress,
    address _wethAddress,
    address _ttffUniPool,
    address _ttff
  ) {
    owner = msg.sender;
    require(_protocolVaultAddress != address(0), "Zero address");
    protocolVaultAddress = _protocolVaultAddress;
    protocolVault = IProtocolVault(protocolVaultAddress);
    require(_ttffPoolAddress != address(0), "Zero address");
    ttffPoolAddress = _ttffPoolAddress;
    ttffPool = ITTFFPool(ttffPoolAddress);
    require(_uniswapV2AdapterAddress != address(0), "Zero address");
    uniswapV2AdapterAddress = _uniswapV2AdapterAddress;
    uniV2Adapter = IUniswapV2Adapter(uniswapV2AdapterAddress);
    require(_tradeAddress != address(0), "Zero address");
    trade = ITradeFromUniswapV2(_tradeAddress);
    require(_wethAddress != address(0), "Zero address");
    wethAddress = _wethAddress;
    weth = IWeth(wethAddress);
    require(_ttffUniPool != address(0), "zero address");
    ttffUniPool = _ttffUniPool;
    ttff = _ttff;
    value1 = 0;
    value2 = 10 * 10**18;
    value3 = 20 * 10**18;
    value4 = 30 * 10**18;
    protocolVaultPercentage = 25 * 10**18;
    removePercentage1 = 25;
    removePercentage2 = 15;
  }

  /*=============== Functions =====================*/
  /*=============== External Functions =====================*/
  /// @notice Chainlink Keeper method calls vaultPercentOfTotal method
  function performUpkeep(bytes calldata performData) external override {
    (, uint256 _percent, ) = price.getLPTTFFPrice(0);
    require(
      (_percent >= value1 && _percent <= value2) ||
        (_percent > value2 && _percent <= value3) ||
        (_percent > value4)
    );
    vaultPercentOfTotal();
    performData;
  }

  /// @notice Checking the upkeepNeeded condition
  function checkUpkeep(bytes calldata checkData)
    external
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    (, uint256 _percent, ) = price.getLPTTFFPrice(0);
    upkeepNeeded =
      (_percent >= value1 && _percent <= value2) ||
      (_percent > value2 && _percent <= value3) ||
      (_percent > value4);
    performData = checkData;
  }

  /*=============== Public Functions =====================*/
  /// @notice Setting ethereum pool addresses
  /// @param _ethPoolAddress The ethereum pool contract address
  function setEthPool(address _ethPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isEthPoolSetted, "Already setted");
    require(_ethPoolAddress != address(0), "Zero address");
    isEthPoolSetted = true;
    ethPoolAddress = _ethPoolAddress;
    ethPool = IEthereumPool(ethPoolAddress);
    emit EthPoolSetted(ethPoolAddress);
    return ethPoolAddress;
  }

  /// @notice Setting price contract address
  /// @param _priceAddress The price contract address
  function setPrice(address _priceAddress) public onlyOwner returns (address) {
    require(!isPriceSetted, "Already setted");
    require(_priceAddress != address(0), "Zero address");
    isPriceSetted = true;
    price = IPrice(_priceAddress);
    emit PriceSetted(_priceAddress);
    return _priceAddress;
  }

  /*=============== Internal Functions =====================*/
  /// @notice The range of percent is determined and the related internal function is triggered
  function vaultPercentOfTotal() internal {
    (, uint256 _percent, ) = price.getLPTTFFPrice(0);
    IUniswapV2Pool _ttffUni = IUniswapV2Pool(ttffUniPool);
    ERC20 _ttff = ERC20(ttff);
    uint256 _ttffAmount = _ttff.balanceOf(ttffPoolAddress);

    if (_percent >= value1 && _percent <= value2) {
      if (_ttffUni.balanceOf(uniswapV2AdapterAddress) != 0) {
        processValue1ToValue2();
      } else if (_ttffAmount != 0) {
        trade.redeemTTFF();
      } else {
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to Protocol Vault failed");
      }
    } else if (_percent > value2 && _percent <= value3) {
      if (_ttffUni.balanceOf(uniswapV2AdapterAddress) != 0) {
        processValue2ToValue3();
      } else if (_ttffAmount != 0) {
        trade.redeemTTFF();
      } else {
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to Protocol Vault failed");
      }
    } else if (_percent > value4) {
      processMoreThanValue4();
    }
  }

  /// @notice Triggers to occur in the range of 0 - 10:
  /// @dev removeLiquidity() : removePercentage1%(25%) of LP Token is withdrawn with fees
  /// @dev redeemTTFF() : Existing ttffs are reedem
  /// @dev feedVault() : 100% of Ethereum Pool is transferred to Vault
  function processValue1ToValue2() internal returns (bool) {
    uniV2Adapter.removeLiquidity(removePercentage1);
    trade.redeemTTFF();
    uint256 _amount = weth.balanceOf(ethPoolAddress);
    bool _success = ethPool.feedVault(_amount);
    require(_success, "Transfer to Protocol Vault failed");
    emit TransferToVault(ethPoolAddress, protocolVaultAddress, _amount);
    return true;
  }

  /// @notice Triggers to occur in the range of 10 - 20:
  /// @dev removeLiquidity() : removePercentage2%(15%) of LP Token is withdrawn with fees
  /// @dev redeemTTFF() : Existing ttffs are reedem
  /// @dev feedVault() : 100% of Eth Pool is transferred to Vault
  function processValue2ToValue3() internal returns (bool) {
    uniV2Adapter.removeLiquidity(removePercentage2);
    trade.redeemTTFF();
    uint256 _amount = weth.balanceOf(ethPoolAddress);
    bool _success = ethPool.feedVault(_amount);
    require(_success, "Transfer to Protocol Vault failed");
    emit TransferToVault(ethPoolAddress, protocolVaultAddress, _amount);
    return true;
  }

  /// @notice Triggers to occur in the range of 30 - >:
  /// @dev feedPool() : _newPercent of Eth Pool is transferred to Vault
  function processMoreThanValue4() internal returns (bool) {
    (uint256 _totalBalance, uint256 _percent, ) = price.getLPTTFFPrice(0);
    uint256 _newPercent = _percent.sub(protocolVaultPercentage);
    uint256 _amount = _totalBalance.mul(_newPercent).div(10**20);
    bool _success = protocolVault.feedPool(_amount);
    require(_success, "Transfer to Ethereum Pool failed");
    emit TransferToETHPool(protocolVaultAddress, ethPoolAddress, _amount); 
    return true;
  }
}
