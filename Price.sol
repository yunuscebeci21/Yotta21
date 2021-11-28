// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapPool } from "./interfaces/IUniswapPool.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IWeth } from "./interfaces/IWeth.sol";
import { IPrice } from "./interfaces/IPrice.sol";

contract Price is IPrice {
  using SafeMath for uint256;

  /* ================ Events ================== */
  /// @notice An event thats emitted when Uniswap V2 Pools setting
  event UniPoolsSetted(address[] _components, address[] _uniPools);
  /// @notice An event thats emitted when ProtocolVault contract setting
  event ProtocolVaultSetted(address _protocolVaultAddress);
  /// @notice An event thats emitted when  EthereumPool contract setting
  event EthPoolSetted(address _ethPoolAddress);
  /// @notice An event thats emitted when TTFFPool contract setting
  event TTFFPoolSetted(address _ttffPoolAddress);
  /// @notice An event thats emitted when UniswapV2Adapter contract setting
  event UniswapV2AdapterSetted(address _uniswapV2Adapter);

  /* ================ State Variables ================== */

  /// @notice Address of contract creator
  address public owner;
  /// @notice Address of otta univ2
  address public ottaUniPool;
  /// @notice Address of ttff univ2
  address public ttffUniPool;
  /// @notice Address of link univ2
  address public linkTokenUniPool;
  /// @notice Address of taum
  address public taum;
  /// @notice Address of ttff
  address public ttff;
  /// @notice Address of uniswapV2 adapter
  address public uniswapV2Adapter;
  /// @notice Address of ttffpool contract
  address public ttffPoolAddress;
  /// @notice Address of ethpool contract
  address public ethPoolAddress;
  /// @notice Address of protocolvault contract
  address public protocolVaultAddress;
  /// @notice Address of weth
  address public wethAddress;
  /// @notice Addresses of component array
  address[] public components;
  /// @notice Set status of this contract
  bool public isUniPoolsSetted;
  bool public isProtocolVaultSetted;
  bool public isTTFFPoolSetted;
  bool public isEthPoolSetted;
  bool public isUniswapV2AdapterSetted;
  /// @notice Map of components univ2
  mapping(address => address) private componentsUniPools;
  /// @notice Importing weth methods
  IWeth public weth;

  /* ================ Modifier ================== */
  /// @notice Throws if the sender is not owner
  modifier onlyOwner() {
    require(msg.sender == owner, "Only Owner");
    _;
  }

  /* ================ Constructor ================== */
  constructor(
    address _weth,
    address _linkTokenUniPool,
    address _ttffUniPool,
    address _ottaUniPool,
    address _taum,
    address _ttff,
    address[] memory _components
  ) {
    owner = msg.sender;
    require(_weth != address(0), "zero address");
    weth = IWeth(_weth);
    wethAddress = _weth;
    require(_linkTokenUniPool != address(0), "zero address");
    linkTokenUniPool = _linkTokenUniPool;
    require(_ttffUniPool != address(0), "zero address");
    ttffUniPool = _ttffUniPool;
    require(_ottaUniPool != address(0), "zero address");
    ottaUniPool = _ottaUniPool;
    require(_taum != address(0), "zero address");
    taum = _taum;
    require(_ttff != address(0), "zero address");
    ttff = _ttff;
    require(_components.length > 0, "zero components");
    components = _components;
  }

  /* ================ Functions ================== */
  /* ================ External Functions ================== */
  /// @inheritdoc IPrice
  function getComponentPrice(address _componentAddress)
    external
    view
    override
    returns (uint256 _componentPrice)
  {
    address _componentPool = componentsUniPools[_componentAddress];
    IUniswapPool _component = IUniswapPool(_componentPool);
    address _token = _component.token0();
    if (_token == wethAddress) {
      (uint256 _reserveWeth, uint256 _reserveComponent, ) = _component
        .getReserves();
      _componentPrice = _reserveWeth.mul(10**18).div(_reserveComponent);
    } else {
      (uint256 _reserveComponent, uint256 _reserveWeth, ) = _component
        .getReserves();
      _componentPrice = _reserveWeth.mul(10**18).div(_reserveComponent);
    }
  }

  /// @inheritdoc IPrice
  function getOttaPrice() external view override returns (uint256 _ottaPrice) {
    IUniswapPool _otta = IUniswapPool(ottaUniPool);
    address _token = _otta.token0();
    if (_token == wethAddress) {
      (uint256 _reserveWeth, uint256 _reserveOtta, ) = _otta.getReserves();
      _ottaPrice = _reserveWeth.mul(10**18).div(_reserveOtta);
    } else {
      (uint256 _reserveOtta, uint256 _reserveWeth, ) = _otta.getReserves();
      _ottaPrice = _reserveWeth.mul(10**18).div(_reserveOtta);
    }
  }

  /// @inheritdoc IPrice
  function getTtffPrice() external view override returns (uint256 _ttffPrice) {
    IUniswapPool _ttff = IUniswapPool(ttffUniPool);
    address _token = _ttff.token0();
    if (_token == wethAddress) {
      (uint256 _reserveWeth, uint256 _reserveTtf, ) = _ttff.getReserves();
      _ttffPrice = _reserveWeth.mul(10**18).div(_reserveTtf);
    } else {
      (uint256 _reserveTtf, uint256 _reserveWeth, ) = _ttff.getReserves();
      _ttffPrice = _reserveWeth.mul(10**18).div(_reserveTtf);
    }
  }

  /// @inheritdoc IPrice
  function getTaumPrice(uint256 _ethAmount)
    external
    view
    override
    returns (
      uint256 _totalAmount,
      uint256 _protocolPercent,
      uint256 _taumPrice
    )
  {
    uint256 _poolAndVaultBalance = (weth.balanceOf(ethPoolAddress))
      .add(weth.balanceOf(protocolVaultAddress))
      .sub(_ethAmount);
    ERC20 _ttff = ERC20(ttff);
    uint256 _ttffAmount = _ttff
      .balanceOf(ttffPoolAddress)
      .mul(this.getTtffPrice())
      .div(10**18);
    IUniswapPool _ttffPool = IUniswapPool(ttffUniPool);
    uint256 _percent = _ttffPool.balanceOf(uniswapV2Adapter).mul(10**20).div(
      _ttffPool.totalSupply()
    );
    uint256 _reserveWeth;
    if (_ttffPool.token0() == wethAddress) {
      (_reserveWeth, , ) = _ttffPool.getReserves();
    } else {
      (, _reserveWeth, ) = _ttffPool.getReserves();
    }
    uint256 _reserveAmountInUniswap = (_reserveWeth.mul(2)).mul(_percent).div(
      10**20
    );

    ERC20 _taum = ERC20(taum);
    _totalAmount = _poolAndVaultBalance.add(_reserveAmountInUniswap).add(
      _ttffAmount
    );
    _protocolPercent = weth.balanceOf(protocolVaultAddress).mul(10**20).div(
      _totalAmount
    );
    _taumPrice = _totalAmount.mul(10**18).div(_taum.totalSupply());
  }

  /* ================ Public Functions ================== */
  /// @notice Setting uni pool addresses
  /// @param _components The array of component adddresses
  /// @param _uniPools The array of component uni pools
  function setUniPools(
    address[] calldata _components,
    address[] calldata _uniPools
  ) public onlyOwner returns (address[] calldata, address[] calldata) {
    require(!isUniPoolsSetted, "Already setted");
    require(_components.length == _uniPools.length, "not equals");
    isUniPoolsSetted = true;
    for (uint256 i = 0; i < _uniPools.length; i++) {
      componentsUniPools[_components[i]] = _uniPools[i];
    }
    emit UniPoolsSetted(_components, _uniPools);
    return (_components, _uniPools);
  }

  /// @notice Setting protocol vault addresses
  /// @param _protocolVaultAddress The protocol vault address
  function setProtocolVault(address _protocolVaultAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isProtocolVaultSetted, "Already setted");
    require(_protocolVaultAddress != address(0), "zero address");
    isProtocolVaultSetted = true;
    protocolVaultAddress = _protocolVaultAddress;
    emit ProtocolVaultSetted(protocolVaultAddress);
    return protocolVaultAddress;
  }

  /// @notice Setting ttff pool addresses
  /// @param _ttffPoolAddress The ttff pool contract address
  function setTTFFPool(address _ttffPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isTTFFPoolSetted, "Already setted");
    require(_ttffPoolAddress != address(0), "zero address");
    isTTFFPoolSetted = true;
    ttffPoolAddress = _ttffPoolAddress;
    emit TTFFPoolSetted(ttffPoolAddress);
    return ttffPoolAddress;
  }

  /// @notice Setting eth pool addresses
  /// @param _ethPoolAddress The eth pool contract address
  function setEthPool(address _ethPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isEthPoolSetted, "Already setted");
    require(_ethPoolAddress != address(0), "zero address");
    isEthPoolSetted = true;
    ethPoolAddress = _ethPoolAddress;
    emit EthPoolSetted(ethPoolAddress);
    return ethPoolAddress;
  }

  /// @notice Setting uniswapV2Adapter addresses
  /// @param _uniswapV2Adapter The uniswapV2Adapter contract address
  function setUniswapV2Adapter(address _uniswapV2Adapter)
    public
    onlyOwner
    returns (address)
  {
    require(!isUniswapV2AdapterSetted, "Already setted");
    require(_uniswapV2Adapter != address(0), "zero address");
    isUniswapV2AdapterSetted = true;
    uniswapV2Adapter = _uniswapV2Adapter;
    emit UniswapV2AdapterSetted(uniswapV2Adapter);
    return uniswapV2Adapter;
  }
}
