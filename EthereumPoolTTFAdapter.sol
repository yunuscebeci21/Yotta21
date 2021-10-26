// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import {IBasicIssuanceModule} from "./tokenSet/IBasicIssuanceModule.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IEthereumPoolTTFAdapter} from "./interfaces/IEthereumPoolTTFAdapter.sol";
import {ITradeComponents} from "./interfaces/ITradeComponents.sol";
import {IEthereumPool} from "./interfaces/IEthereumPool.sol";
import {ITTFPool} from "./interfaces/ITTFPool.sol";

/// @title EthereumPoolTTFAdapter
/// @author Yotta21
contract EthereumPoolTTFAdapter is IEthereumPoolTTFAdapter {

    /* ================= Events ================= */

    event ManagerSetted(address _manager);
    event TradeFromUniswapV2Setted(address _tradeFromUniswapV2Address);
    event TTFPoolSetted(address _ttfPoolAddress);
    event EthPoolSetted(address _ethPoolAddress);

    /* ================= State Variables ================= */

    // Address of Wrapped Ether
    address private wethAddress;
    // Address of ttf pool
    address public ttfPoolAddress;
    // Address of Ethereum pool
    address payable public ethPoolAddress;
    // Address of owner
    address public owner;
    // address of manager
    address public manager;
    // Address of issuance module
    address public issuanceModuleAddress;
    // Address of tradefromuniswap 
    address public tradeFromUniswapV2Address;
    // maximum size of uint256
    uint256 public constant MAX_INT = 2**256 - 1;
    // set states of this contracts
    bool public isManagerSetted;
    bool public isTradeFromUniswapV2;
    bool public isTtfPoolSetted;
    bool public isEthPoolSetted;
    // Importing Ethereum pool methods
    IEthereumPool public ethPool;
    // Importing index liquidity pool methods
    ITTFPool public ttfPool;
    // Importing Component buyer methods
    ITradeComponents public trade;
    // Importing issuance module methods
    IBasicIssuanceModule public issuanceModule;

    /* ================= Modifiers ================= */

    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner or Manager");
        _;
    }

    /*
     * Throws if the sender is not eth pool 
     */
    modifier onlyEthPool() {
        require(msg.sender == ethPoolAddress, "Only Ether Pool");
        _;
    }


    /* ================= Constructor ================= */
    constructor(address _manager, address _wethAddress, address _issuanceModuleAddress) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_wethAddress != address(0), "zero address");
        wethAddress = _wethAddress;
        require(_issuanceModuleAddress != address(0), "zero address");
        issuanceModuleAddress = _issuanceModuleAddress;
        issuanceModule = IBasicIssuanceModule(issuanceModuleAddress);
    }

    /* =================  Functions ================= */
    /* ================= Public Functions ================= */

    /*
     * Notice: Setting manager address
     * Param:
     * '_manager' address of manager
     */
    function setManager(address _manager) public onlyOwner returns(address){
        require(!isManagerSetted, "Already setted");
        require(_manager != address(0), "zero address");
        isManagerSetted = true;
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }
    /*
     * Notice: Setting trade address
     * Param:
     * '_tradeFromUniswapV2Address' address of trade
     */
    function setTradeFromUniswapV2(address _tradeFromUniswapV2Address)
        public
        onlyOwner
        returns (address)
    { 
        require(!isTradeFromUniswapV2, "Already setted");
        require(_tradeFromUniswapV2Address != address(0), "zero address");
        isTradeFromUniswapV2 = true;
        tradeFromUniswapV2Address = _tradeFromUniswapV2Address;
        trade = ITradeComponents(tradeFromUniswapV2Address);
        emit TradeFromUniswapV2Setted(tradeFromUniswapV2Address);
        return tradeFromUniswapV2Address;
    }

    /*
     * Notice: Setting ttf pool address and importing methods
     * Param:
     * '_ttfPoolAddress' address of index liquidity pool
     */
    function setTTFPool(address _ttfPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isTtfPoolSetted, "Already setted");
        require(_ttfPoolAddress != address(0), "zero address");
        isTtfPoolSetted = true;
        ttfPoolAddress = _ttfPoolAddress;
        ttfPool = ITTFPool(ttfPoolAddress);
        emit TTFPoolSetted(ttfPoolAddress);
        return (ttfPoolAddress);
    }

    /*
     * Notice: Setting ethereum pool address and importing methods
     * Param:
     * '_ethPoolAddress' address of ethereum pool
     */
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

    /* ================= External Functions ================= */
    
    /* Notice: Up to MAX_INT, issuanceModule address is approved to components in ttf
     */
    function approveComponents() external onlyOwner {
        address _ttfAddress = ttfPool.getTTF();
            ISetToken _ttf = ISetToken(_ttfAddress);
            address[] memory _components = _ttf.getComponents();
            for (uint256 j = 0; j < _components.length; j++) {
                ERC20 _component = ERC20(_components[j]);
                _component.approve(issuanceModuleAddress, MAX_INT);
            }
    }

    /*
     * Notice: getter method of required components for create index
     * Params:
     * '_index' address of index. Must be inherit from ISetToken
     * '_quantity' quantity of index to issue
     * Returns: array of component addresses and array of required quantity
     *
     */
    function getRequiredComponents(ISetToken _ttf, uint256 _quantity)
        external
        override
        onlyEthPool
        returns (address[] memory, uint256[] memory)
    {
        (
            address[] memory _components,
            uint256[] memory _values
        ) = issuanceModule.getRequiredComponentUnitsForIssue(_ttf, _quantity);

        return (_components, _values);
    }

    /*
     * Notice: It buys components
     * Param:
     * '_component' address of component to buy
     * '_value' Quantity of component to buy
     * '_wethQuantity' quantity of wrapped ether to swap with component
     */
    function buyTTFComponents(
        address _component,
        uint256 _value,
        uint256 _wethQuantity
    ) external override onlyEthPool returns (bool) {
        trade.buyComponents(_component, _value, _wethQuantity);
        return true;
    }

    /*
     * Notice: Minting index to index liquidity pool
     */
    function issueTTF() external override onlyEthPool returns (bool) {
        address _ttfAddress = ttfPool.getTTF();
        ISetToken _ttf = ISetToken(_ttfAddress);
        uint256 _quantity = ethPool._issueQuantity();
        issuanceModule.issue(_ttf, _quantity, ttfPoolAddress);
        return (true);
    }

 
}
