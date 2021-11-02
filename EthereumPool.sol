// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Adapter} from "./interfaces/IUniswapV2Adapter.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IEthereumPoolTTFAdapter} from "./interfaces/IEthereumPoolTTFAdapter.sol";
import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

import {IEthereumPool} from "./interfaces/IEthereumPool.sol";
import {IPrice} from "./interfaces/IPrice.sol";
import {ITTFPool} from "./interfaces/ITTFPool.sol";
import {ITradeComponents} from "./interfaces/ITradeComponents.sol";
import {ITaum} from "./interfaces/ITaum.sol";

/// @title EthereumPool
/// @author Yotta21
contract EthereumPool is IEthereumPool {

    using SafeMath for uint256;
    
    /*================== Events ===================*/

    event ManagerSetted(address _manager);
    event PriceSetted(address _priceAddress);
    event MinValueSetted(uint256 _minValue);
    event LimitSetted(uint256 _limitValue);
    event TTFPercentageForAmountSetted(uint256 _ttfPercentage);
    event ProtocolVaultPercentageSetted(uint256 _protocolVaultPercentage);

    /*================== State Variables ===================*/
    // Address of the contract creator
    address public owner;
    // address of manager
    address public manager;
    // address of index pool address
    address public ttfPoolAddress;
    // Address of the UniswapAdapter
    address public uniswapV2AdapterAddress;
    // Address of Ethereum Vault
    address public protocolVault;
    // Address of Gradual Taum Contract
    address public protocolGradualAddress;
    // Address of buyer
    address public tradeFromUniswapV2Address;
    // ETH Limit for investment
    uint256 public limit;
    // Current Value of limit
    uint256 public limitValue;
    // Minimum value of accepted Ethereum from protocol
    uint256 public minValue;
    // Quantity of issue
    uint256 public issueQuantity;
    // Determines how much ttf will be issue
    uint256 public ttfPercentageForAmount;
    // protocol vault percentage
    uint256 public protocolVaultPercentage;
    // Status of set in this contract
    bool public isPriceSetted;
    // importing Index Liquidity Pool methods
    ITTFPool public ttfPool;
    //Importing Uniswap adapter methods
    IUniswapV2Adapter public uniswapV2Adapter;
    //Importing EthPoolTokenIndexAdapter methods
    IEthereumPoolTTFAdapter public ethPoolTTFAdapter;
    // Importing Price Contract Methods
    IPrice public price;
    // Importing wrapped ether methods(Deposit-Withdraw and IERC20 methods)
    IWeth public weth;
    // Importing trade methods
    ITradeComponents public trade;
    // importing Taum contract interface as taum
    ITaum public taum;

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
        address _ttfPool,
        address _uniswapV2Adapter,
        address _ethPoolTTFAdapter,
        address _protocolVault,
        address _taumAddress,
        address _tradeFromUniswapV2Address,
        address _protocolGradualAddress
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        limit = 0;
        limitValue = _limitValue;
        require(_weth != address(0), "zero address");
        weth = IWeth(_weth);
        require(_ttfPool != address(0), "zero address");
        ttfPoolAddress = _ttfPool;
        ttfPool = ITTFPool(ttfPoolAddress);
        require(_uniswapV2Adapter != address(0), "zero address");
        uniswapV2AdapterAddress = _uniswapV2Adapter;
        uniswapV2Adapter = IUniswapV2Adapter(uniswapV2AdapterAddress);
        require(_ethPoolTTFAdapter != address(0), "zero address");
        ethPoolTTFAdapter = IEthereumPoolTTFAdapter(_ethPoolTTFAdapter);
        require(_protocolVault != address(0), "zero address");
        protocolVault = _protocolVault;
        require(_taumAddress != address(0), "zero address");
        taum = ITaum(_taumAddress);
        require(_tradeFromUniswapV2Address != address(0), "zero address");
        tradeFromUniswapV2Address = _tradeFromUniswapV2Address;
        trade = ITradeComponents(tradeFromUniswapV2Address);
        require(_protocolGradualAddress != address(0), "zero address");
        protocolGradualAddress = _protocolGradualAddress;
        ttfPercentageForAmount = 20;
    }

    /*============ Public Functions ================ */
    /*
     * Notice: Setting manager address
     * Param:
     * '_manager' address of ethereum vault
     */
    function setManager(address _manager) public onlyOwner returns (address) {
        require(_manager != address(0), "zero address");
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }

    
    /* Notice: Setting price contract address methods
     * Params:
     * '_priceAddress' The price contract address.
     */
    function setPrice(address _priceAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isPriceSetted, "Already Setted");
        require(_priceAddress != address(0), "zero address");
        isPriceSetted = true;
        price = IPrice(_priceAddress);
        emit PriceSetted(_priceAddress);
        return _priceAddress;
    }

    /*
     * Notice: Setting new minimum value
     * Param:
     * '_minValue' The address of minimum value
     */
    function setMinValue(uint256 _minValue) public onlyOwner returns(uint256){
        minValue = _minValue;
        emit MinValueSetted(_minValue);
        return minValue;
    }

    /*
     * Notice: Setting value of limit
     * Param:
     * _limitValue' The limit value
     */
    function setLimit(uint256 _limitValue) public onlyOwner returns (uint256) {
        require(_limitValue != 0, "not zero");
        limitValue = _limitValue;
        emit LimitSetted(limitValue);
        return (limitValue);
    }

    /*
     * Notice: Setting ttf Percentage for ttf amount
     * Param:
     * _ttfPercentage' The ttf Percentage
     */
    function setTTFPercentage(uint256 _ttfPercentage) public onlyOwner returns (uint256) {
        require(_ttfPercentage != 0, "not zero");
        ttfPercentageForAmount = _ttfPercentage;
        emit TTFPercentageForAmountSetted(ttfPercentageForAmount);
        return (ttfPercentageForAmount);
    }

    /*
     * Notice: Setting 
     * Param:
     * _ttfPercentage' The limit value
     */
    function setProtocolVaultPercentage(uint256 _protocolVaultPercentage) public onlyOwner returns (uint256) {
        require(_protocolVaultPercentage != 0, "not zero");
        protocolVaultPercentage = _protocolVaultPercentage;
        emit ProtocolVaultPercentageSetted(protocolVaultPercentage);
        return (protocolVaultPercentage);
    }


    /*
     * Notice: Auto trigger from ChainLink Keeper.
     *         If limit is full, this method will call indexCreate and sendETH methods
     */
    function limitController() internal {
        limit = 0;
        bool successCreate = ttfCreate();
        require(successCreate, "Fail index create");
        bool succesIssue = ethPoolTTFAdapter.issueTTF();
        require(succesIssue, "Fail issue index");
        bool successSend = sendWETH();
        require(successSend, "Fail send Eth");
        bool successGet = uniswapV2Adapter.bringTTFsFromPool();
        require(successGet, "Fail bring indexes from pool");
        bool successAdd = uniswapV2Adapter.addLiquidity();
        require(successAdd, "Fail add liquidity to uni");
        emit TTFCreated(ttfPool.getTTF(), issueQuantity);
    }

    /*
     * Notice: It will send ETH to adapter
     */
    function sendWETH() internal returns (bool) {
        uint256 _transferValue = weth.balanceOf(address(this));
        weth.transfer(uniswapV2AdapterAddress, _transferValue);
        emit SendWETHtoLiquidity(uniswapV2AdapterAddress, _transferValue);
        return true;
    }

    /*
     * Notice: Creating indexes
     * Return:
     * 'state' The state of create to index
     */
    function ttfCreate() internal returns (bool) {
        address _ttfAddress = ttfPool.getTTF();
        ISetToken _ttf = ISetToken(_ttfAddress);
        weth.transfer(tradeFromUniswapV2Address, weth.balanceOf(address(this)).div(2));
        uint256 _wethToIndex = weth.balanceOf(tradeFromUniswapV2Address);
        uint256 _price;
        (
            address[] memory _components,
            uint256[] memory _values
        ) = ethPoolTTFAdapter.getRequiredComponents(_ttf, 1*10**18);
        for (uint256 i = 0; i < _components.length; i++) {
            uint256 _preComponentPrice = price.getComponentPrice(
                _components[i]
            );
            _price = _price.add(_values[i].mul(_preComponentPrice).div(10**18));
        }

        uint256 _quantity = (_wethToIndex.mul(10**18)).div(_price);
        issueQuantity = _quantity.sub((_quantity.mul(ttfPercentageForAmount)).div(100));

        (
            address[] memory _components1,
            uint256[] memory _values1
        ) = ethPoolTTFAdapter.getRequiredComponents(_ttf, issueQuantity);

        (, uint256[] memory _values2) = ethPoolTTFAdapter.getRequiredComponents(
            _ttf,
            _quantity
        );

        require(_values.length > 0, "zero values length");

        for (uint256 i = 0; i < _components.length; i++) {
            uint256 _componentPrice = price.getComponentPrice(_components1[i]);
            uint256 _wethToComponent = (_values2[i].mul(_componentPrice)).div(
                10**18
            );
            ethPoolTTFAdapter.buyTTFComponents(
                _components1[i],
                _values1[i],
                _wethToComponent
            );
        }
        trade.residualWeth();
        return true;
    }

    

    /*============ External Functions ================ */
    /*
     * Notice: This function is recieving ETH from user
     *         This function sends 25% of recieved eth to Ethereum Vault
     *         This function is calling mintTaumToken function
     *         When user send ETH to pool it will mint Taum Token to user
     */
    receive() external payable {
        require(msg.value > minValue, "insufficient amount entry");
        address _userAddress = msg.sender;
        uint256 _ethQuantity = msg.value;
        weth.deposit{value: _ethQuantity}();
        uint256 _ethToVault = _ethQuantity.mul(protocolVaultPercentage).div(100);
        limit = limit.add(_ethQuantity).sub(_ethToVault);
        bool _successTransfer = weth.transfer(protocolVault, _ethToVault);
        require(_successTransfer, "Transfer failed.");
        (, , uint256 _taumPrice) = price.getTaumPrice(_ethQuantity);
        uint256 _taumAmount = (_ethQuantity.mul(10**18)).div(_taumPrice);
        taum.tokenMint(_userAddress, _taumAmount);
        emit MintTaumTokenToUser(_userAddress, _taumAmount);
    }

    /*
     * Returns:percentage of issue quantity
     */
    function _issueQuantity() external view virtual override returns (uint256) {
        return issueQuantity;
    }

    function addLimit(uint256 _limit) external override{
        require(msg.sender == protocolVault, "only protocol vault");
        limit = limit.add(_limit);
    }

    /*
     * Notice: It is for protocol gradual contract
     *         Sends wrapped ether to Vault, if needs.
     */
    function feedVault(uint256 _amount) external override returns (bool) {
        require(msg.sender == protocolGradualAddress, "Only Gradual Taum");
        limit = 0;
        bool _successTransfer = weth.transfer(protocolVault, _amount);
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
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = limit >= limitValue;
        performData = checkData;
    }

    /*
     * Notice: Chainlink Keeper method calls limitController method
     *
     */

    function performUpkeep(bytes calldata performData) external {
        require((limit >= limitValue), "not epoch");
        limitController();
        performData;
    }
}
