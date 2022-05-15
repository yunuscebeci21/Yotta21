// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IUniswapV2Adapter } from "./interfaces/IUniswapV2Adapter.sol";
import { IWeth } from "./external/IWeth.sol";
import { IEthereumPoolTTFFAdapter } from "./interfaces/IEthereumPoolTTFFAdapter.sol";
import { ISetToken } from "./external/ISetToken.sol";
import { IEthereumPool } from "./interfaces/IEthereumPool.sol";
import { IPrice } from "./interfaces/IPrice.sol";
import { ITTFFPool } from "./interfaces/ITTFFPool.sol";
import { ITradeFromUniswapV2 } from "./interfaces/ITradeFromUniswapV2.sol";
import { ILPTTFF } from "./interfaces/ILPTTFF.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title EthereumPool
/// @author Yotta21
/// @notice TTFF process is controlled.
contract EthereumPool is IEthereumPool, KeeperCompatibleInterface {
  using SafeMath for uint256;

  /*================== Events ===================*/
  /// @notice An event thats emitted when price contract address setting
  event PriceSetted(address _priceAddress);
  /// @notice An event thats emitted when minimum value setting
  event MinValueSetted(uint256 _minValue);
  /// @notice An event thats emitted when limit setting
  event LimitSetted(uint256 _limitValue);

  /*================== State Variables ===================*/
  /// @notice Address of contract creator
  address public owner;
  /// @notice Address of timelock
  address public timelockForOtta;
  address public timelockForMesh;
  /// @notice Address of ttff pool address
  address public ttffPoolAddress;
  /// @notice Address of the UniswapAdapter
  address public uniswapV2AdapterAddress;
  /// @notice Address of Ethereum Vault
  address public protocolVault;
  /// @notice Address of Gradual LPTTFF Contract
  address public protocolGradualAddress;
  /// @notice Address of buyer
  address public tradeFromUniswapV2Address;
  /// @notice ETH Limit for investment
  uint256 public limit;
  /// @notice Current Value of limit
  uint256 public limitValue;
  /// @notice Minimum value of accepted Ethereum from protocol
  uint256 public minValue;
  /// @notice Quantity of issue
  uint256 public issueQuantity;
  /// @notice Determines how much ttff will be issue
  uint256 public ttffPercentageForAmount;
  /// @notice protocol vault percentage
  uint256 public protocolVaultPercentage;
  /// @notice Status of set in this contract
  bool public isPriceSetted;
  /// @notice Importing ttff Pool methods
  ITTFFPool public ttffPool;
  /// @notice Importing Uniswap adapter methods
  IUniswapV2Adapter public uniswapV2Adapter;
  /// @notice Importing EthPoolTTFFAdapter methods
  IEthereumPoolTTFFAdapter public ethPoolTTFFAdapter;
  /// @notice Importing Price Contract Methods
  IPrice public price;
  /// @notice Importing wrapped ether methods(Deposit-Withdraw and IERC20 methods)
  IWeth public weth;
  /// @notice Importing trade methods
  ITradeFromUniswapV2 public trade;
  /// @notice Importing LPTTFF contract interface as lpTtff
  ILPTTFF public lpTtff;

  /*================== Modifiers =====================*/
  /// @notice Throws if the sender is not an owner
  modifier onlyOwner() {
    require(msg.sender == owner, "Only Owner");
    _;
  }

  /// @notice Throws if the sender is not an timelock
  modifier onlyTimeLock() {
    require(msg.sender == timelockForOtta || msg.sender == timelockForMesh, "Only Timelock");
    _;
  }

  /*================== Constructor =====================*/
  constructor(
    address _timelockForOtta,
    address _timelockForMesh,
    address _weth,
    address _ttffPool,
    address _uniswapV2Adapter,
    address _ethPoolTTFFAdapter,
    address _protocolVault,
    address _lpTtffAddress,
    address _tradeFromUniswapV2Address,
    address _protocolGradualAddress
  ) {
    owner = msg.sender;
    require(_timelockForOtta != address(0), "Zero address");
    timelockForOtta = _timelockForOtta;
    timelockForMesh = _timelockForMesh;
    limit = 0;
    limitValue = 0.01 * 10 ** 18;
    minValue = 0.005 * 10 ** 18;
    ttffPercentageForAmount = 20; // Bu değerlerin okunmasına ihtiyaç var mı?
    protocolVaultPercentage = 25; //  ---
    require(_weth != address(0), "Zero address");
    weth = IWeth(_weth);
    require(_ttffPool != address(0), "Zero address");
    ttffPoolAddress = _ttffPool;
    ttffPool = ITTFFPool(ttffPoolAddress);
    require(_uniswapV2Adapter != address(0), "Zero address");
    uniswapV2AdapterAddress = _uniswapV2Adapter;
    uniswapV2Adapter = IUniswapV2Adapter(uniswapV2AdapterAddress);
    require(_ethPoolTTFFAdapter != address(0), "Zero address");
    ethPoolTTFFAdapter = IEthereumPoolTTFFAdapter(_ethPoolTTFFAdapter);
    require(_protocolVault != address(0), "Zero address");
    protocolVault = _protocolVault;
    require(_lpTtffAddress != address(0), "Zero address");
    lpTtff = ILPTTFF(_lpTtffAddress);
    require(_tradeFromUniswapV2Address != address(0), "Zero address");
    tradeFromUniswapV2Address = _tradeFromUniswapV2Address;
    trade = ITradeFromUniswapV2(tradeFromUniswapV2Address);
    require(_protocolGradualAddress != address(0), "Zero address");
    protocolGradualAddress = _protocolGradualAddress;
  }

  /*============ Functions ================ */
  /// @notice This function is recieving ETH from user
  /// @dev This function sends 25% of recieved eth to Protocol Vault
  /// @dev This function is calling tokenMint function
  /// @dev When user send ETH to pool it will mint LPTTFF Token to user
  receive() external payable {
    require(msg.value > minValue, "Insufficient amount entry");
    address _userAddress = msg.sender;
    uint256 _ethQuantity = msg.value;
    weth.deposit{ value: _ethQuantity }();
    uint256 _ethToVault = _ethQuantity.mul(protocolVaultPercentage).div(100);
    limit = limit.add(_ethQuantity).sub(_ethToVault);
    bool _successTransfer = weth.transfer(protocolVault, _ethToVault);
    require(_successTransfer, "Transfer failed");
    //(, , uint256 _lpTtffPrice) = price.getLPTTFFPrice(_ethQuantity);
    uint256 _lpTtffPrice = 0.001*10**18;
    uint256 _lpTtffAmount = (_ethQuantity.mul(10**18)).div(_lpTtffPrice);
    lpTtff.tokenMint(_userAddress, _lpTtffAmount);
    emit MintLPTTFFTokenToUser(_userAddress, _lpTtffAmount);
  }

  /*============ External Functions ================ */
  /// @inheritdoc IEthereumPool
  function addLimit(uint256 _limit) external override {
    require(msg.sender == protocolVault, "Only Protocol Vault");
    limit = limit.add(_limit);
  }

  /// @inheritdoc IEthereumPool
  function feedVault(uint256 _amount) external override returns (bool) {
    require(msg.sender == protocolGradualAddress, "Only Gradual LPTTFF");
    limit = 0;
    bool _successTransfer = weth.transfer(protocolVault, _amount);
    require(_successTransfer, "Transfer failed.");
    return true;
  }

  /// @notice Chainlink Keeper method calls limitController method
  function performUpkeep(bytes calldata performData) external override {
    require((limit >= limitValue), "Not epoch");
    limitController();
    performData;
  }

  /// @notice Checking the upkeepNeeded condition
  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    upkeepNeeded = limit >= limitValue;
    performData = checkData;
  }

  /// @inheritdoc IEthereumPool
  function _issueQuantity() external view virtual override returns (uint256) {
    return issueQuantity;
  }

  /*============ Public Functions ================ */
  /// @notice Setting price contract address methods.
  /// @param '_priceAddress' The price contract address.
  function setPrice(address _priceAddress) public onlyOwner returns (address) {
    require(!isPriceSetted, "Already setted");
    require(_priceAddress != address(0), "Zero address");
    isPriceSetted = true;
    price = IPrice(_priceAddress);
    emit PriceSetted(_priceAddress);
    return _priceAddress;
  }

  /// @notice Setting new minimum value
  /// @dev Can be changed by governance decision
  /// @param '_minValue' The address of minimum value
  function setMinValue(uint256 _minValue)
    public
    onlyTimeLock
    returns (uint256)
  {
    minValue = _minValue;
    emit MinValueSetted(_minValue);
    return minValue;
  }

  /// @notice Setting value of limit
  /// @dev Can be changed by governance decision
  /// @param _limitValue The limit value
  function setLimit(uint256 _limitValue) public onlyTimeLock returns (uint256) {
    require(_limitValue != 0, "Not zero value");
    limitValue = _limitValue;
    emit LimitSetted(limitValue);
    return (limitValue);
  }

  /*============ Internal Functions ================ */
  /// @notice Auto trigger from ChainLink Keeper.
  /// @dev If limit is full, TTFF process begins.
  function limitController() internal {
    limit = 0;
    bool successCreate = ttffCreate();
    require(successCreate, "Fail TTFF create");
    bool succesIssue = ethPoolTTFFAdapter.issueTTFF();
    require(succesIssue, "Fail issue TTFF");
    bool successSend = sendWETH();
    require(successSend, "Fail send Weth");
    bool successGet = uniswapV2Adapter.bringTTFFsFromPool();
    require(successGet, "Fail bring TTFFs from TTFF Pool");
    bool successAdd = uniswapV2Adapter.addLiquidity();
    require(successAdd, "Fail add liquidity to UniswapV2");
    emit TTFFCreated(ttffPool.getTTFF(), issueQuantity); 
  }

  /// @notice It will send ETH to adapter
  function sendWETH() internal returns (bool) {
    uint256 _transferValue = weth.balanceOf(address(this));
    weth.transfer(uniswapV2AdapterAddress, _transferValue);
    emit SendWETHtoLiquidity(uniswapV2AdapterAddress, _transferValue);
    return true;
  }

  /// @notice TTFF creation start
  function ttffCreate() internal returns (bool) {
    address _ttfAddress = ttffPool.getTTFF();
    ISetToken _ttff = ISetToken(_ttfAddress);
    weth.transfer(
      tradeFromUniswapV2Address,
      weth.balanceOf(address(this)).div(2)
    );
    uint256 _wethToTTFF = weth.balanceOf(tradeFromUniswapV2Address);
    uint256 _price;
    (
      address[] memory _components,
      uint256[] memory _values
    ) = ethPoolTTFFAdapter.getRequiredComponents(_ttff, 1 * 10**18);
    for (uint256 i = 0; i < _components.length; i++) {
      uint256 _preComponentPrice = price.getComponentPrice(_components[i]);
      _price = _price.add(_values[i].mul(_preComponentPrice).div(10**18));
    }
    uint256 _quantity = (_wethToTTFF.mul(10**18)).div(_price);
    issueQuantity = _quantity.sub(
      (_quantity.mul(ttffPercentageForAmount)).div(100)
    );
    (
      address[] memory _components1,
      uint256[] memory _values1
    ) = ethPoolTTFFAdapter.getRequiredComponents(_ttff, issueQuantity);
    (, uint256[] memory _values2) = ethPoolTTFFAdapter.getRequiredComponents(
      _ttff,
      _quantity
    );
    require(_values.length > 0, "Zero values length");
    for (uint256 i = 0; i < _components.length; i++) {
      uint256 _componentPrice = price.getComponentPrice(_components1[i]);
      uint256 _wethToComponent = (_values2[i].mul(_componentPrice)).div(10**18);
      ethPoolTTFFAdapter.buyTTFFComponents(
        _components1[i],
        _values1[i],
        _wethToComponent
      );
    }
    trade.residualWeth();
    return true;
  } 
}
