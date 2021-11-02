// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV2Router02} from "./uniswap/IUniswapV2Router02.sol";
import {IEthereumPoolTTFAdapter} from "./interfaces/IEthereumPoolTTFAdapter.sol";
import {ITradeComponents} from "./interfaces/ITradeComponents.sol";
import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import {ITTFPool} from "./interfaces/ITTFPool.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IBasicIssuanceModule} from "./tokenSet/IBasicIssuanceModule.sol";

contract TradeFromUniswapV2 is ITradeComponents {

    /* ================= Events ================= */

    event ProtocolVaultSetted(address _protocolVault);
    event EthPoolSetted(address _ethPool);
    event PriceSetted(address _price);
    event KeeperControllerSetted(address _keeperController);
    event ProtocolGradualSetted(address _protocolGradualAddress);
    event TTFPoolSetted(address _ttfPoolAddress);

    /* ================= State Variables ================= */

    // Address of EthereumPoolTTFAdapter
    address public ethPoolTTFAdapterAddress;
    // Address of KeeperController
    address public keeperController;
    // Address of uniswap swap router
    address public swapRouterAddress;
    // Address of owner
    address public owner;
    //address of manager 
    address public manager;
    // Address of wrapped eth
    address public wethAddress;
    // Address of Protocol Vault.
    address public protocolVault;
    // Address of ethereum pool
    address public ethPool;
    // Address of protocol gradual contract
    address public protocolGradualAddress;
    // Address of price contract
    address public priceAddress;
    // Address of Link Token
    address public linkAddress;
    // deadline for uniswap
    uint256 public constant DEADLINE = 5 hours;
    // maximum size of uint256
    uint256 public constant MAX_INT = 2**256 - 1;
    // set state of this contracts
    bool public isProtocolVaultSetted;
    bool public isEthPoolSetted;
    bool public isPriceSetted;
    bool public isKeeperControllerSetted;
    bool public isProtocolGradualSetted;
    bool public isTTFPoolSetted;
    // Importing swap router methods
    IUniswapV2Router02 public swapRouter;
    // Importing EthPoolTokenIndexAdapter methods
    IEthereumPoolTTFAdapter public ethPoolTTFAdapter;
    // Importing index liquidity pool methods
    ITTFPool public ttfPool;
    // Importing wrapped ether methods
    IWeth public weth;
    // Importing issuance module methods
    IBasicIssuanceModule public issuanceModule;
    
    

    /* ================= Modifiers ================= */
    /*
     * Throws if the sender is not owner or manager
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only owner");
        _;
    }

    /* ================= Constructor ================= */
    constructor(
        address _manager,
        address _ethPoolTTFAdapter,
        address _wethAddress,
        address _swapRouterAddress,
        address _issuanceModuleAddress,
        address _linkAddress
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_ethPoolTTFAdapter != address(0), "zero address");
        ethPoolTTFAdapterAddress = _ethPoolTTFAdapter;
        ethPoolTTFAdapter  = IEthereumPoolTTFAdapter(ethPoolTTFAdapter);
        require(_wethAddress != address(0), "zero address");
        wethAddress = _wethAddress;
        weth = IWeth(wethAddress);
        require(_swapRouterAddress != address(0), "zero address");
        swapRouterAddress = _swapRouterAddress;
        swapRouter = IUniswapV2Router02(swapRouterAddress);
        require(_issuanceModuleAddress != address(0), "zero address");
        issuanceModule = IBasicIssuanceModule(_issuanceModuleAddress);
        require(_linkAddress != address(0), "zero address");
        linkAddress = _linkAddress;
    }

    /* ================= Functions ================= */
    /* ================= Public Functions ================= */

    /*
     * Notice: Setting manager address
     * Param:
     * '_manager' address of ethereum vault
     */
    /*function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }*/

    /*
     * Notice: Setting protocol vault address
     * Param:
     * '_ethVault' address of protocol vault
     */
    function setProtocolVault(address _protocolVault)
        public
        onlyOwner
        returns (address)
    {
        require(!isProtocolVaultSetted, "Already setted");
        require(_protocolVault != address(0), "zero address");
        isProtocolVaultSetted = true;
        protocolVault = _protocolVault;
        emit ProtocolVaultSetted(protocolVault);
        return protocolVault;
    }

    /* Notice: Setting ethereum pool address
     * Param:
     * '_ethPool' address of ethereum pool
     */
    function setEthPool(address _ethPool)
        public
        onlyOwner
        returns (address)
    {
        require(!isEthPoolSetted, "Already setted");
        require(_ethPool != address(0), "zero address");
        isEthPoolSetted = true;
        ethPool = _ethPool;
        emit EthPoolSetted(ethPool);
        return ethPool;
    }

    /*
     * Notice: Setting price contract address
     * Param:
     * '_priceAddress' address of price contract
     */
    function setPrice(address _priceAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isPriceSetted, "Already setted");
        require(_priceAddress != address(0), "zero address");
        isPriceSetted = true;
        priceAddress = _priceAddress;
        emit PriceSetted(priceAddress);
        return priceAddress;
    }

    /*
     * Notice: Setting keeper controller contract address
     * Param:
     * '_keeperAddress' address of keeper controller contract
     */
    function setKeeperController(address _keeperControllerAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isKeeperControllerSetted, "Already setted");
        require(_keeperControllerAddress != address(0), "zero address");
        isKeeperControllerSetted = true;
        keeperController = _keeperControllerAddress;
        emit KeeperControllerSetted(keeperController);
        return keeperController;
    }

    /*
     * Notice: Setting gradual taum contract address
     * Param:
     * '_gradualTaum' address of gradual taum contract
     */
    function setProtocolGradual(address _protocolGradual)
        public
        onlyOwner
        returns (address)
    {
        require(!isProtocolGradualSetted, "Already setted");
        require(_protocolGradual != address(0), "zero address");
        isProtocolGradualSetted = true;
        protocolGradualAddress = _protocolGradual;
        emit ProtocolGradualSetted(protocolGradualAddress);
        return (protocolGradualAddress);
    }

    /*
     * Notice: Setting index liquidity pool contract address
     * Param:
     * '_indexPoolAddress' address of index liquidity pool contract
     */
    function setTTFPool(address _ttfPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isTTFPoolSetted, "Already setted");
        require(_ttfPoolAddress != address(0), "zero address");
        isTTFPoolSetted = true;
        ttfPool = ITTFPool(_ttfPoolAddress);
        emit TTFPoolSetted(_ttfPoolAddress);
        return (_ttfPoolAddress);
    }

    /*
     * Notice: Calling approve methods from ttfs, wrapped ether, link
               Using MAX_INT for approve quantity
     */
    function approveComponents() public onlyOwner {
        weth.approve(swapRouterAddress, MAX_INT);
        ERC20 _link = ERC20(linkAddress);
        _link.approve(swapRouterAddress, MAX_INT);
        address _ttfAddress = ttfPool.getTTF();
        ISetToken _ttf = ISetToken(_ttfAddress);
        address[] memory _components = _ttf.getComponents();
        for (uint256 j = 0; j < _components.length; j++) {
            ERC20 _component = ERC20(_components[j]);
            _component.approve(swapRouterAddress, MAX_INT);
        }
    }

    /* ================= External Functions ================= */

    /*
     * Notice: swaps wrapped ether to needed token on uniswapV2
     */
    function buyComponents(
        address _component,
        uint256 _value,
        uint256 _wethQuantity
    ) external override {
        require(
            msg.sender == ethPoolTTFAdapterAddress ||
                msg.sender == keeperController,
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

    /*
     * Notice: swaps token to wrapped ether on uniswapV2
     */
    function sellComponents(address _component)
        internal
        returns (bool)
    {
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

    /*
     * Notice: Burning index and selling components for weth
     *          It sends weth to eth vault
     */
    function redeemTTF() external override {
        require(msg.sender == protocolGradualAddress, "only gradual taum");
        address _ttfAddress = ttfPool.getTTF();
        ttfPool.sendTTF(); 
        ISetToken _set = ISetToken(_ttfAddress);
        uint256 _quantity = _set.balanceOf(address(this));
        issuanceModule.redeem(_set, _quantity, address(this));
        (
            address[] memory _components,
        ) = issuanceModule.getRequiredComponentUnitsForIssue(_set, _quantity);
        for (uint256 i = 0; i < _components.length; i++) {
            bool _success = sellComponents(_components[i]);
            require(_success, "Failed on sell component in redeem");
        }
    }

    /*
     * Notice: after buying transfers to residual weth vault
     *          
     */
    function residualWeth() external override {
        require(msg.sender == ethPool || msg.sender == keeperController, "only ethPool");
        weth.transfer(protocolVault, weth.balanceOf(address(this)));
    }
}
