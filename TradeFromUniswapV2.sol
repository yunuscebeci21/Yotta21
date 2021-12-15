// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapV2Router02 } from "./external/IUniswapV2Router02.sol";
import { IEthereumPoolTTFFAdapter } from "./interfaces/IEthereumPoolTTFFAdapter.sol";
import { ITradeFromUniswapV2 } from "./interfaces/ITradeFromUniswapV2.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { ITTFFPool } from "./interfaces/ITTFFPool.sol";
import { IWeth } from "./external/IWeth.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IBasicIssuanceModule } from "./external/IBasicIssuanceModule.sol";

contract TradeFromUniswapV2 is ITradeFromUniswapV2 {
  /* ================= Events ================= */
  /// @notice An event thats emitted when ProtocolVault contract address setting
  event ProtocolVaultSetted(address _protocolVault);
  /// @notice An event thats emitted when EthereumPool contract address setting
  event EthPoolSetted(address _ethPool);
  /// @notice An event thats emitted when ProtocolGradual contract address setting
  event ProtocolGradualSetted(address _protocolGradualAddress);
  /// @notice An event thats emitted when TTFFPool contract address setting
  event TTFFPoolSetted(address _ttffPoolAddress);

  /* ================= State Variables ================= */
  /// @notice Address of EthereumPoolTTFFAdapter
  address public ethPoolTTFFAdapterAddress;
  /// @notice Address of uniswap swap router
  address public swapRouterAddress;
  /// @notice Address of owner
  address public owner;
  /// @notice Address of manager
  address public manager;
  /// @notice Address of wrapped eth
  address public wethAddress;
  /// @notice Address of Protocol Vault.
  address public protocolVault;
  /// @notice Address of ethereum pool
  address public ethPool;
  /// @notice Address of protocol gradual contract
  address public protocolGradualAddress;
  /// @notice Address of price contract
  address public priceAddress;
  /// @notice Address of Link Token
  address public linkAddress;
  /// @notice Deadline for uniswap
  uint256 public constant DEADLINE = 5 hours;
  /// @notice Maximum size of uint256
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice Set state of this contracts
  bool public isProtocolVaultSetted;
  bool public isEthPoolSetted;
  bool public isProtocolGradualSetted;
  bool public isTTFFPoolSetted;
  //// @notice Importing swap router methods
  IUniswapV2Router02 public swapRouter;
  /// @notice Importing EthPoolTokenIndexAdapter methods
  IEthereumPoolTTFFAdapter public ethPoolTTFFAdapter;
  /// @notice Importing index liquidity pool methods
  ITTFFPool public ttffPool;
  /// @notice Importing wrapped ether methods
  IWeth public weth;
  /// @notice Importing issuance module methods
  IBasicIssuanceModule public issuanceModule;

  /* ================= Modifiers ================= */
  /// @notice Throws if the sender is not owner
  modifier onlyOwner() {
    require(msg.sender == owner, "Only Owner");
    _;
  }

  /* ================= Constructor ================= */
  constructor(
    address _ethPoolTTFFAdapter,
    address _wethAddress,
    address _swapRouterAddress,
    address _issuanceModuleAddress
  ) {
    owner = msg.sender;
    require(_ethPoolTTFFAdapter != address(0), "Zero address");
    ethPoolTTFFAdapterAddress = _ethPoolTTFFAdapter;
    ethPoolTTFFAdapter = IEthereumPoolTTFFAdapter(ethPoolTTFFAdapter);
    require(_wethAddress != address(0), "Zero address");
    wethAddress = _wethAddress;
    weth = IWeth(wethAddress);
    require(_swapRouterAddress != address(0), "Zero address");
    swapRouterAddress = _swapRouterAddress;
    swapRouter = IUniswapV2Router02(swapRouterAddress);
    require(_issuanceModuleAddress != address(0), "Zero address");
    issuanceModule = IBasicIssuanceModule(_issuanceModuleAddress);
  }

  /* ================= Functions ================= */
  /* ================= External Functions ================= */
  /// @inheritdoc ITradeFromUniswapV2
  function buyComponents(
    address _component,
    uint256 _value,
    uint256 _wethQuantity
  ) external override {
    require(
      msg.sender == ethPoolTTFFAdapterAddress,
      "Only Protocol"
    );
    address[] memory _path = new address[](2);
    _path[0] = wethAddress;
    _path[1] = _component;
    swapRouter.swapTokensForExactTokens(
      _value,
      _wethQuantity,
      _path,
      msg.sender,
      block.timestamp + DEADLINE
    );
    emit ComponentBought(_component, _value);
  }

  /// @notice Swaps token to wrapped ether on uniswapV2
  function sellComponents(address _component) internal returns (bool) {
    ERC20 _componentToken = ERC20(_component);
    address[] memory _path = new address[](2);
    _path[0] = _component;
    _path[1] = wethAddress;
    swapRouter.swapExactTokensForTokens(
      _componentToken.balanceOf(address(this)),
      0,
      _path,
      protocolVault,
      block.timestamp + DEADLINE
    );
    emit ComponentSold(_component, _componentToken.balanceOf(address(this)));
    return true;
  }

  /// @inheritdoc ITradeFromUniswapV2
  function redeemTTFF() external override {
    require(msg.sender == protocolGradualAddress, "Only Protocol Gradual");
    address _ttffAddress = ttffPool.getTTFF();
    ttffPool.sendTTFF();
    ISetToken _set = ISetToken(_ttffAddress);
    uint256 _quantity = _set.balanceOf(address(this));
    issuanceModule.redeem(_set, _quantity, address(this));
    (address[] memory _components, ) = issuanceModule
      .getRequiredComponentUnitsForIssue(_set, _quantity);
    for (uint256 i = 0; i < _components.length; i++) {
      bool _success = sellComponents(_components[i]);
      require(_success, "Failed on sell component in redeem");
    }
  }

  /// @inheritdoc ITradeFromUniswapV2
  function residualWeth() external override {
    require(
      msg.sender == ethPool,
      "Only Ethereum Pool"
    );
    weth.transfer(protocolVault, weth.balanceOf(address(this)));
  }

  /* ================= Public Functions ================= */
  /// @notice Setting protocol vault address
  /// @param _protocolVault Address of protocol vault
  function setProtocolVault(address _protocolVault)
    public
    onlyOwner
    returns (address)
  {
    require(!isProtocolVaultSetted, "Already setted");
    require(_protocolVault != address(0), "Zero address");
    isProtocolVaultSetted = true;
    protocolVault = _protocolVault;
    emit ProtocolVaultSetted(protocolVault);
    return protocolVault;
  }

  /// @notice Setting ethereum pool address
  /// @param _ethPool Address of ethereum pool
  function setEthPool(address _ethPool) public onlyOwner returns (address) {
    require(!isEthPoolSetted, "Already setted");
    require(_ethPool != address(0), "Zero address");
    isEthPoolSetted = true;
    ethPool = _ethPool;
    emit EthPoolSetted(ethPool);
    return ethPool;
  }

  /// @notice Setting gradual taum contract address
  /// @param _protocolGradual Address of gradual taum contract
  function setProtocolGradual(address _protocolGradual)
    public
    onlyOwner
    returns (address)
  {
    require(!isProtocolGradualSetted, "Already setted");
    require(_protocolGradual != address(0), "Zero address");
    isProtocolGradualSetted = true;
    protocolGradualAddress = _protocolGradual;
    emit ProtocolGradualSetted(protocolGradualAddress);
    return (protocolGradualAddress);
  }

  /// @notice Setting ttff liquidity pool contract address
  /// @param _ttffPoolAddress address of ttff pool contract
  function setTTFFPool(address _ttffPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isTTFFPoolSetted, "Already setted");
    require(_ttffPoolAddress != address(0), "Zero address");
    isTTFFPoolSetted = true;
    ttffPool = ITTFFPool(_ttffPoolAddress);
    emit TTFFPoolSetted(_ttffPoolAddress);
    return (_ttffPoolAddress);
  }

  /// @notice Calling approve methods from ttffs, wrapped ether, link
  /// Using MAX_INT for approve quantity
  function approveComponents() public onlyOwner {
    weth.approve(swapRouterAddress, MAX_INT);
    address _ttffAddress = ttffPool.getTTFF();
    ISetToken _ttff = ISetToken(_ttffAddress);
    address[] memory _components = _ttff.getComponents();
    for (uint256 j = 0; j < _components.length; j++) {
      ERC20 _component = ERC20(_components[j]);
      _component.approve(swapRouterAddress, MAX_INT);
    }
  }
}
