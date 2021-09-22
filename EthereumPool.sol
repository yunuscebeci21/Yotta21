// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IPoolTokenAdapter} from "./interfaces/IPoolTokenAdapter.sol";
import {IUniswapV2Adapter} from "./interfaces/IUniswapV2Adapter.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IEthPoolTokenIndexAdapter} from "./interfaces/IEthPoolTokenIndexAdapter.sol";
import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

import {IEthereumPool} from "./interfaces/IEthereumPool.sol";
import "./chainlink/KeeperCompatibleInterface.sol";
import {IPrice} from "./interfaces/IPrice.sol";
import {IIndexLiquidityPool} from "./interfaces/IIndexLiquidityPool.sol";
import {IGradualTaum} from "./interfaces/IGradualTaum.sol";
import {IComponentPrice} from "./interfaces/IComponentPrice.sol";
import "./interfaces/IBuyComponents.sol";
import "./interfaces/ITaum.sol";

/// @title Uniswap Adapter
/// @author Yotta21
contract EthereumPool is IEthereumPool, KeeperCompatibleInterface {
    using SafeMath for uint256;

    /*================== State Variables ===================*/
    // Address of the contract creator
    address public owner;
    // address of manager
    address public manager;
    // address of index pool address
    address public indexPoolAddress;
    // Address of the UniswapAdapter
    address public uniswapV2AdapterAddress;
    //Address of the poolTokenAdapter
    address private poolTokenAdapterAddress;
    // Address of Ethereum Vault
    address public ethVault;
    // Address of Gradual Taum Contract
    address private gradualTaumAddress;
    // Address of buyer
    address public buyerAddress;
    // Status of taum contract address set
    bool private isTaumSetted = false;
    // ETH Limit for investment
    uint256 public limit;
    // Current Value of limit
    uint256 public limitValue;
    // Minimum value of accepted Ethereum from protocol
    uint256 public minValue;
    // Quantity of issue
    uint256 public issueQuantity;
    // importing Index Liquidity Pool methods
    IIndexLiquidityPool private indexPool;
    //Importing Uniswap adapter methods
    IUniswapV2Adapter public uniswapV2Adapter;
    //Importing EthPoolTokenIndexAdapter methods
    IEthPoolTokenIndexAdapter private indexTokenAdapter;
    // Importing PoolTokenAdapter methods
    IPoolTokenAdapter private poolTokenAdapter;
    // Importing Price Contract Methods
    IPrice private price;
    // Importing Gradual Taum Contract Methods
    IGradualTaum private gradualTaum;
    // Importing wrapped ether methods(Deposit-Withdraw and IERC20 methods)
    IWeth private weth;
    // Importing buyer methods
    IBuyComponents private buyer;
    // importing Taum contract interface as taum
    ITaum private taum;

    /*================== Modifiers =====================*/
    /**
     * Throws if the sender is not an owner of this contract
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /*================== Constructor =====================*/
    constructor(
        address _manager,
        uint256 _limitValue,
        address _weth,
        address _indexPool,
        address _uniswapV2Adapter,
        address _indexTokenAdapter,
        address _poolTokenAdapter,
        address _priceAddress,
        address _ethVault,
        address _taumAddress,
        address _buyerAddress,
        address _gradualTaumAddress
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        limit = 0;
        limitValue = _limitValue;
        require(_weth != address(0), "zero address");
        weth = IWeth(_weth);
        require(_indexPool != address(0), "zero address");
        indexPoolAddress = _indexPool;
        indexPool = IIndexLiquidityPool(indexPoolAddress);
        require(_uniswapV2Adapter != address(0), "zero address");
        uniswapV2AdapterAddress = _uniswapV2Adapter;
        uniswapV2Adapter = IUniswapV2Adapter(uniswapV2AdapterAddress);
        require(_indexTokenAdapter != address(0), "zero address");
        indexTokenAdapter = IEthPoolTokenIndexAdapter(_indexTokenAdapter);
        require(_poolTokenAdapter != address(0), "zero address");
        poolTokenAdapterAddress = _poolTokenAdapter;
        poolTokenAdapter = IPoolTokenAdapter(poolTokenAdapterAddress);
        require(_priceAddress != address(0), "zero address");
        price = IPrice(_priceAddress);
        require(_ethVault != address(0), "zero address");
        ethVault = _ethVault;
        require(_taumAddress != address(0), "zero address");
        taum = ITaum(_taumAddress);
        require(_buyerAddress != address(0), "zero address");
        buyerAddress = _buyerAddress;
        buyer = IBuyComponents(buyerAddress);
        require(_gradualTaumAddress != address(0), "zero address");
        gradualTaumAddress = _gradualTaumAddress;
        gradualTaum = IGradualTaum(gradualTaumAddress);
    }

    /*============ Public Functions ================ */
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }
    /*
     * Notice: Setting buyer contract
     * Param:
     * _buyerAddress' The address of new buyer contract
     */
    function setBuyer(address _buyerAddress)
        public
        onlyOwner
        returns (address _newBuyer)
    {
        require(_buyerAddress != address(0), "zero address");
        buyerAddress = _buyerAddress;
        buyer = IBuyComponents(buyerAddress);
        return buyerAddress;
    }

    /*
     * Notice: Setting taum address only once
     * Return: 
     * '_taumTokenAddress' The new taum address.
     */
    function setTaum(address _taumTokenAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isTaumSetted, "Already Setted");
        require(_taumTokenAddress != address(0), "zero address");
        taum = ITaum(_taumTokenAddress);
        emit TaumSetted(_taumTokenAddress);
        isTaumSetted = true;
        return (_taumTokenAddress);
    }

    /*
     * Notice: Setting value of limit
     * Param:
     * _limitValue' The limit value
     */
    function setLimit(uint256 _limitValue) public onlyOwner returns (uint256) {
        limitValue = _limitValue;
        emit LimitSetted(_limitValue);
        return (limitValue);
    }

    /* Notice: Setting price contract address methods
     * Params:
     * '_priceAddress' The price contract address.
     * Return:
     * '_priceAddress' The current price contract address.
     * Requirements:
     * '_priceAddress' cannot be the zero address.
     */
    function setPrice(address _priceAddress)
        public
        onlyOwner
        returns (address newPriceAddress)
    {
        require(_priceAddress != address(0), "zero address");
        price = IPrice(_priceAddress);
        return _priceAddress;
    }

    /*
     * Notice: Setting new minimum value
     * Param:
     * '_minValue' The address of minimum value
     */
    function setMinValue(uint256 _minValue) public onlyOwner {
        minValue = _minValue;
        emit MinValueChanged(_minValue);
    }

    /*
     * Notice: Auto trigger from ChainLink Keeper.
     *         If limit is full, this method will call indexCreate and sendETH methods
     */
    function limitController() internal {
        limit = 0;
        bool successCreate = indexCreate();
        require(successCreate, "Fail index create");
        bool succesIssue = indexTokenAdapter.issueIndex();
        require(succesIssue, "Fail issue index");
        bool successSend = sendETH();
        require(successSend, "Fail send Eth");
        bool successGet = uniswapV2Adapter.bringIndexesFromPool();
        require(successGet, "Fail bring indexes from pool");
        bool successAdd = uniswapV2Adapter.addLiquidity();
        require(successAdd, "Fail add liquidity to uni");
    }

    /*
     * Notice: It will send ETH to adapter
     */
    function sendETH() internal returns (bool) {
        uint256 _transferValue = weth.balanceOf(address(this));
        weth.transfer(uniswapV2AdapterAddress, _transferValue);
        emit SendETHtoLiquidity(uniswapV2AdapterAddress, _transferValue);
        return (true);
    }

    /*
     * Notice: Creating indexes
     * Return:
     * 'state' The state of create to index
     */
    function indexCreate() internal returns (bool state) {
        address _index = indexPool.getIndex();
        weth.transfer(
            buyerAddress,
            weth.balanceOf(address(this)).div(2)
        );
        uint256 _wethToIndex = weth.balanceOf(buyerAddress);
        uint256 _price = price.getTtfPrice();
        uint256 _quantity = (_wethToIndex.mul(10**18)).div(_price);
        _quantity -= (_quantity.mul(5)).div(100);
        ISetToken _ttf = ISetToken(_index);
        issueQuantity = _quantity;
        (
            address[] memory _components,
            uint256[] memory _values
        ) = indexTokenAdapter.getRequiredComponents(_ttf, _quantity);
        require(_values.length > 0, "zero values length");

        for (uint256 i = 0; i < _components.length; i++) {
            uint256 _componentPrice = price.getComponentPrice(
                _components[i]
            );
            uint256 _wethToComponent = (_values[i].mul(_componentPrice)).div(10**18);
            bool success = indexTokenAdapter.buyIndexComponents(
                _components[i],
                _values[i],
                _wethToComponent
            );
            require(success, "Component buy failed");
        }
        buyer.residualWeth();
        return true;
    }

    /*
     * Returns:percentage of issue quantity
     */
    function _issueQuantity()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return issueQuantity;
    }

    /*============ External Functions ================ */
    /*
     * Notice: This function is recieving ETH from user
     *         This function sends 25% of recieved eth to Ethereum Vault
     *         This function is calling mintTaumToken function
     *         When user send ETH to pool it will mint Taum Token to user
     */
    receive() external payable override {
        require(msg.value > minValue, "insufficient amount entry");
        address _userAddress = msg.sender;
        uint256 _ethQuantity = msg.value;
        weth.deposit{value: _ethQuantity}();
        uint256 _ethToVault = _ethQuantity.mul(25).div(100);
        limit = limit.add(_ethQuantity).sub(_ethToVault);
        bool _successTransfer = weth.transfer(
            ethVault,
            _ethToVault
        );
        require(_successTransfer, "Transfer failed.");
        (,,uint256 _taumPrice) = price.getTaumPrice();
        uint256 _taumAmount = (_ethQuantity.mul(10**18)).div(_taumPrice);
        taum.tokenMint(_userAddress, _taumAmount);
        //gradualTaum.calculateProtocolPercent();
    }

    /*
     * Notice: It is for gradual taum contract
     *         Sends wrapped ether to Vault, if needs.
     */
    function feedVault(uint256 _amount) external override returns (bool) {
        require(msg.sender == gradualTaumAddress, "Only Gradual Taum");
        limit = 0;
        bool _successTransfer = weth.transfer(ethVault, _amount);
        require(_successTransfer, "Transfer failed.");
        return true;
    }

    /*
     * Notice: Chainlink Keeper method
     *
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = limit >= limitValue;
        performData = checkData;
    }

    /*
     * Notice: Chainlink Keeper method calls limitController method
     *
     */

    function performUpkeep(bytes calldata performData) external override {
        limitController();
        performData;
    }

    /*================== Internal Functions=================*/
    /*
     * Notice: That function is using poolTokenAdapter to get price of Taum Token
     *         That function is using poolTokenAdapter to call _mint function from Taum Token
     *         _userAddress is function caller and it is for _mint function
     */
    /*function mintTaumToken(address _userAddress, uint256 _ethQuantity)
        internal
    {
        poolTokenAdapter.returnTaumToken(_userAddress, _ethQuantity);
    }*/
}
