// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {IUniswapV2Router02} from "./uniswap/IUniswapV2Router02.sol";
import {IEthPoolTokenIndexAdapter} from "./interfaces/IEthPoolTokenIndexAdapter.sol";
import {IBuyComponents} from "./interfaces/IBuyComponents.sol";
import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import {IIndexLiquidityPool} from "./interfaces/IIndexLiquidityPool.sol";
import "./interfaces/IWeth.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IBasicIssuanceModule} from "./tokenSet/IBasicIssuanceModule.sol";

contract BuyFromUniswapV2 is IBuyComponents {
    /* ================= State Variables ================= */

    // Address of EthPoolTokenIndexAdapter
    address private ethPoolTokenIndexAdapter;
    // Address of KeeperController
    address private keeperController;
    // Address of uniswap swap router
    address public swapRouterAddress;
    // Address of owner
    address public owner;
    //address of manager 
    address public manager;
    // Address of wrapped eth
    address private wethAddress;
    // Address of Ethereum Vault. To send Eth after sell
    address public ethVault;
    // Address of ethereum pool
    address public ethPool;
    // Address of gradual taum contract
    address private gradualTaumAddress;
    // Address of price contract
    address private priceAddress;
    // deadline for uniswap
    uint256 public constant DEADLINE = 5 hours;
    // maximum size of uint256
    uint256 public constant MAX_INT = 2**256 - 1;
    // set state of protocol contracts
    bool public isVaultSetted = false;
    bool public isGradualSetted = false;
    bool public isIndexPoolSetted = false;
    bool public isPoolSetted = false;
    // Importing swap router methods
    IUniswapV2Router02 internal swapRouter;
    // Importing EthPoolTokenIndexAdapter methods
    IEthPoolTokenIndexAdapter internal adapter;
    // Importing index liquidity pool methods
    IIndexLiquidityPool internal indexPool;
    // Importing wrapped ether methods
    IWeth internal weth;
    // Importing issuance module methods
    IBasicIssuanceModule private issuanceModule;

    /* ================= Modifiers ================= */
    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only owner");
        _;
    }

    /* ================= Constructor ================= */
    constructor(
        address _manager,
        address _ethPoolTokenIndexAdapter,
        address _wethAddress,
        address _swapRouterAddress,
        address _priceAddress,
        address _issuanceModuleAddress,
        address _keeperControllerAddress
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_ethPoolTokenIndexAdapter != address(0), "zero address");
        ethPoolTokenIndexAdapter = _ethPoolTokenIndexAdapter;
        adapter = IEthPoolTokenIndexAdapter(ethPoolTokenIndexAdapter);
        require(_wethAddress != address(0), "zero address");
        wethAddress = _wethAddress;
        weth = IWeth(wethAddress);
        require(_swapRouterAddress != address(0), "zero address");
        swapRouterAddress = _swapRouterAddress;
        swapRouter = IUniswapV2Router02(swapRouterAddress);
        require(_priceAddress != address(0), "zero address");
        priceAddress = _priceAddress;
        require(_issuanceModuleAddress != address(0), "zero address");
        issuanceModule = IBasicIssuanceModule(_issuanceModuleAddress);
        require(_keeperControllerAddress != address(0), "zero address");
        keeperController = _keeperControllerAddress;
    }

    /* ================= Functions ================= */
    /* ================= Public Functions ================= */
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }
    /*
     * Notice: Setting ethereum vault address
     * Param:
     * '_ethVault' address of ethereum vault
     */
    function setEthVault(address _ethVault)
        public
        onlyOwner
        returns (address ethVaultAddress)
    {
        require(!isVaultSetted, "Already setted");
        require(_ethVault != address(0), "zero address");
        ethVault = _ethVault;
        emit EthVaultSetted(ethVault);
        isVaultSetted = true;
        return ethVault;
    }

    /* Notice: Setting ethereum pool address
     * Param:
     * '_ethPool' address of ethereum pool
     */
    function setEthPool(address _ethPool)
        public
        onlyOwner
        returns (address ethPoolAddress)
    {
        require(!isPoolSetted, "Already setted");
        require(_ethPool != address(0), "zero address");
        ethPool = _ethPool;
        emit EthPoolSetted(ethPool);
        isPoolSetted = true;
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
        returns (address newPriceAddress)
    {
        require(_priceAddress != address(0), "zero address");
        priceAddress = _priceAddress;
        return priceAddress;
    }

    /*
     * Notice: Setting gradual taum contract address
     * Param:
     * '_gradualTaum' address of gradual taum contract
     */
    function setGradual(address _gradualTaum)
        public
        onlyOwner
        returns (address newGradualTaumAddress)
    {
        require(!isGradualSetted, "Already setted");
        require(_gradualTaum != address(0), "zero address");
        gradualTaumAddress = _gradualTaum;
        emit GradualTaumSetted(gradualTaumAddress);
        isGradualSetted = true;
        return (gradualTaumAddress);
    }

    /*
     * Notice: Setting index liquidity pool contract address
     * Param:
     * '_indexPoolAddress' address of index liquidity pool contract
     */
    function setIndexPool(address _indexPoolAddress)
        public
        onlyOwner
        returns (address indexPoolAddress)
    {
        require(!isIndexPoolSetted, "Already setted");
        require(_indexPoolAddress != address(0), "zero address");
        indexPool = IIndexLiquidityPool(_indexPoolAddress);
        emit IndexLiquidityPoolSetted(_indexPoolAddress);
        isIndexPoolSetted = true;
        return (_indexPoolAddress);
    }

    /*
     * Notice: Calling approve methods from indexes and wrapped ether
               Using MAX_INT for approve quantity
     */
    function approveComponents() public {
        weth.approve(swapRouterAddress, MAX_INT);
        address _index = indexPool.getIndex();
        ISetToken _ttf = ISetToken(_index);
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
            msg.sender == ethPoolTokenIndexAdapter ||
                msg.sender == keeperController ||
                msg.sender == priceAddress,
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
    function sellComponents(address _component, uint256 _value)
        internal
        returns (bool status)
    {
        address[] memory _path = new address[](2);
        _path[0] = _component;
        _path[1] = wethAddress;
        swapRouter.swapExactTokensForTokens(
            _value,
            0,
            _path,
            ethVault,
            block.timestamp + DEADLINE
        );
        emit ComponentSold(_component, _value);
        return true;
    }

    /*
     * Notice: Burning index and selling components for weth
     *          It sends weth to eth vault
     */
    function redeemIndex() external override {
        require(msg.sender == gradualTaumAddress, "only gradual taum");
        address _index = indexPool.getIndex();
        indexPool.sendIndex(); 
        ISetToken _set = ISetToken(_index);
        uint256 _quantity = _set.balanceOf(address(this));
        issuanceModule.redeem(_set, _quantity, address(this));
        (
            address[] memory _components,
            uint256[] memory _values
        ) = issuanceModule.getRequiredComponentUnitsForIssue(_set, _quantity);
        for (uint256 i = 0; i < _components.length; i++) {
            bool _success = sellComponents(_components[i], _values[i]);
            require(_success, "Failed on sell component in redeem");
        }
    }

    function residualWeth() external override {
        require(msg.sender == ethPool, "only ethPool");
        bool success = weth.transfer(ethVault, weth.balanceOf(address(this)));
        require(success, "Residual weth transfer failed.");
    }
}
