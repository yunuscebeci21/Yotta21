// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IEthereumPool} from "./interfaces/IEthereumPool.sol";
import {ITTFPool} from "./interfaces/ITTFPool.sol";
import {IProtocolVault} from "./interfaces/IProtocolVault.sol";
import {IUniswapV2Adapter} from "./interfaces/IUniswapV2Adapter.sol";
import {ITradeComponents} from "./interfaces/ITradeComponents.sol";
import {IProtocolGradual} from "./interfaces/IProtocolGradual.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IPrice} from "./interfaces/IPrice.sol";
import {IUniswapPool} from "./interfaces/IUniswapPool.sol";

contract GradualTaum is IProtocolGradual {
    using SafeMath for uint256;

    /*================== Events ===================*/

    event ManagerSetted(address _manager);
    event EthPoolSetted(address _ethPoolAddress);
    event PriceSetted(address _priceAddress);
    event TradeFromUniswapV2AdapterSetted(address _tradeFromuniswapV2Address);
    event ValuesSetted(uint256 _value1, uint256 _value2, uint256 _value3, uint256 _value4);
    event ProtocolVaultPercentageSetted(uint256 _protocolVaultPercentage);
    event RemovePercentageSetted(uint256 _removePercentage1, uint256 _removePercentage2);

    /*================== State Variables ===================*/

    // address of owner
    address public owner;
    // address of manager 
    address public manager;
    // address of ethereum pool contract
    address public ethPoolAddress;
    // address of ttf pool contract
    address public ttfPoolAddress;
    // address of ethereum vault contract
    address public protocolVaultAddress;
    // address of uniswap adapter
    address public uniswapV2AdapterAddress;
    // address of ERC20 weth
    address public wethAddress;
    // address of ttf uniV2
    address public ttfUniPool;
    // address of ttf 
    address public ttf;
    // constant value1
    uint256 public value1;
    // constant value2
    uint256 public value2;
    // constant value3
    uint256 public value3;
    // constant value4
    uint256 public value4;
    // percentage of vault in protocol 
    uint256 public protocolVaultPercentage;
    // percentage for processValue1ToValue2 fonction
    uint256 public removePercentage1;
    // percentage for processValue2ToValue3 fonction
    uint256 public removePercentage2;
    // set status of this contract
    bool public isManagerSetted;
    bool public isEthPoolSetted;
    bool public isPriceSetted;
    bool public isTradeFromUniswapV2Setted;
    // importing trade methods
    ITradeComponents public trade;
    // importing UniswapV2Adapter methods
    IUniswapV2Adapter public uniV2Adapter;
    // importing ProtocolVault methods
    IProtocolVault public protocolVault;
    // importing EthereumPool methods
    IEthereumPool public ethPool;
    // importing TTFPool methods
    ITTFPool public ttfPool;
    // importing Price methods
    IPrice public price;
    // importing weth methods
    IWeth public weth;
    
    

    
    /* ================= Modifiers ================= */

    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /*=============== Constructor ========================*/
    constructor(
        address _manager,
        address _protocolVaultAddress,
        address _ttfPoolAddress,
        address _uniswapV2AdapterAddress,
        address _tradeAddress,
        address _wethAddress,
        address _ttfUniPool,
        address _ttf
    )  {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_protocolVaultAddress != address(0), "zero address");
        protocolVaultAddress = _protocolVaultAddress;
        protocolVault = IProtocolVault(protocolVaultAddress);
        require(_ttfPoolAddress != address(0), "zero address");
        ttfPoolAddress = _ttfPoolAddress;
        ttfPool = ITTFPool(ttfPoolAddress);
        require(_uniswapV2AdapterAddress != address(0), "zero address");
        uniswapV2AdapterAddress = _uniswapV2AdapterAddress;
        uniV2Adapter = IUniswapV2Adapter(uniswapV2AdapterAddress);
        require(_tradeAddress != address(0), "zero address");
        trade = ITradeComponents(_tradeAddress);
        require(_wethAddress != address(0), "zero address");
        wethAddress = _wethAddress;
        weth = IWeth(wethAddress);
        require(_ttfUniPool != address(0), "zero address");
        ttfUniPool = _ttfUniPool;
        ttf = _ttf;
        value2 = 10 * 10 ** 18;
        value3 = 20 * 10 ** 18;
        value4 = 30 * 10 ** 18;
        removePercentage1 = 25;
        removePercentage2 = 15;
    }

    /*=============== Functions =====================*/
    /*=============== Public Functions =====================*/

    /*
     * Notice: Setting manager address
     * Params:
     * '_manager' The manager address
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
     * Notice: Setting eth pool addresses
     * Params:
     * '_ethPoolAddress' The eth pool contract address
     */
    function setEthPool(address _ethPoolAddress) public onlyOwner returns(address){
        require(!isEthPoolSetted, "Already setted");
        require(_ethPoolAddress != address(0), "zero address");
        isEthPoolSetted = true;
        ethPoolAddress = _ethPoolAddress;
        emit EthPoolSetted(ethPoolAddress);
        return ethPoolAddress;
    }

    /*
     * Notice: Setting price contract address
     * Params:
     * '_priceAddress' The price contract address
     */
    function setPrice(
        address _priceAddress
    ) public onlyOwner returns(address){
        require(!isPriceSetted, "Already setted");
        require(_priceAddress != address(0), "zero address");
        isPriceSetted = true;
        price = IPrice(_priceAddress);
        emit PriceSetted(_priceAddress);
        return _priceAddress;
    }
    
     /*
     * Notice: Setting trade from uniswapV2 contract address
     * Params:
     * '_tradeFromuniswapV2Address' The trade from uniswapV2 contract address
     */
    function setTradeFromUniswapV2(
        address _tradeFromuniswapV2Address
    ) public onlyOwner returns(address){
        require(!isTradeFromUniswapV2Setted, "Already setted");
        require(_tradeFromuniswapV2Address != address(0), "zero address");
        isTradeFromUniswapV2Setted = true;
        trade = ITradeComponents(_tradeFromuniswapV2Address);
        emit TradeFromUniswapV2AdapterSetted(_tradeFromuniswapV2Address);
        return _tradeFromuniswapV2Address;
    }

     /*
     * Notice: Setting values 
     * Params:
     *    The values to set range
     */
    function setValues(uint256 _value1, uint256 _value2, uint256 _value3, uint256 _value4)
        public
        onlyOwner
        returns (uint256,uint256,uint256,uint256)
    {
        value1 = _value1;
        value2 = _value2;
        value3 = _value3;
        value4 = _value4;
        emit ValuesSetted(value1, value2, value3, value4);
        return (value1, value2, value3, value4);
    }

     /*
     * Notice: Setting protocol Vault Percentage
     * Params:
     * '_protocolVaultPercentage' The new protocol Vault Percentage
     */
    function setProtocolVaultPercentage(uint256 _protocolVaultPercentage)
        public
        onlyOwner
        returns (uint256)
    {
        protocolVaultPercentage = _protocolVaultPercentage;
        emit ProtocolVaultPercentageSetted(protocolVaultPercentage);
        return protocolVaultPercentage;
    }

     /*
     * Notice: Setting Remove Percentage
     * Params:
     * '_removePercentage1' The new first range percentage
     * '_removePercentage2' The new second range percentage
     */
    function setRemovePercentage(uint256 _removePercentage1, uint256 _removePercentage2)
        public
        onlyOwner
        returns (uint256,uint256)
    {
        removePercentage1 = _removePercentage1;
        removePercentage2 = _removePercentage2;
        emit RemovePercentageSetted(removePercentage1, removePercentage2);
        return (removePercentage1, removePercentage2);
    }
    
    

    /*=============== External Functions =====================*/

    /*
     * Notice:  Chainlink Keeper method
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (,uint256 _percent,) = price.getTaumPrice(0);
        upkeepNeeded =
            (_percent >= value1 && _percent <= value2) ||
            (_percent > value2 && _percent <= value3) ||
            (_percent > value4);
        performData = checkData;
    }

    /*
     * Notice:  Chainlink Keeper method calls vaultPercentOfTotal method
     */
    function performUpkeep(bytes calldata performData) external {
        (,uint256 _percent,) = price.getTaumPrice(0);
        require((_percent >= value1 && _percent <= value2) ||
            (_percent > value2 && _percent <= value3) ||
            (_percent > value4));
        vaultPercentOfTotal();
        performData;
    }

    /*=============== Internal Functions =====================*/
    /*
     * Notice: The range of percent is determined and the related internal function is triggered
     */
    function vaultPercentOfTotal() internal {
        (,uint256 _percent,) = price.getTaumPrice(0);
        IUniswapPool _ttfUni = IUniswapPool(ttfUniPool);
        ERC20 _ttf = ERC20(ttf);
        uint256 _ttfAmount = _ttf.balanceOf(ttfPoolAddress);

        if (_percent >= value1 && _percent <= value2) {
            if(_ttfUni.balanceOf(uniswapV2AdapterAddress) != 0){
               processValue1ToValue2();
            }else if(_ttfAmount != 0){
               trade.redeemTTF();
            }else{
               uint256 _amount = weth.balanceOf(ethPoolAddress);
               bool _success = ethPool.feedVault(_amount);
               require(_success, "Transfer to vault failed");
            }
        } else if(_percent > value2 && _percent <= value3) {
            if(_ttfUni.balanceOf(uniswapV2AdapterAddress) != 0){
               processValue2ToValue3();
            }else if(_ttfAmount != 0){
               trade.redeemTTF();
            }else{
               uint256 _amount = weth.balanceOf(ethPoolAddress);
               bool _success = ethPool.feedVault(_amount);
               require(_success, "Transfer to vault failed");
            }
        } else if(_percent > value4) {
               processMoreThanValue4();
        }
        
    }

    /*
     * Notice: Triggers to occur in the range of 0 - 10:
     * 1. removeLiquidity() : removePercentage1% of LP Token is withdrawn with fees
     * 2. redeemTTF() : Existing ttfs are reedem
     * 3. feedVault() : 100% of Eth Pool is transferred to Vault
     */
    function processValue1ToValue2() internal returns (bool status) {
        uniV2Adapter.removeLiquidity(removePercentage1);
        trade.redeemTTF();
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to vault failed");
        emit TransferToVault(ethPoolAddress, protocolVaultAddress, _amount);
        return true;
    }

    /*
     * Notice: Triggers to occur in the range of 10 - 20:
     * 1. removeLiquidity() : removePercentage2% of LP Token is withdrawn with fees
     * 2. redeemTTF() : Existing ttfs are reedem
     * 3. feedVault() : 100% of Eth Pool is transferred to Vault
     */
    function processValue2ToValue3() internal returns (bool) {
        uniV2Adapter.removeLiquidity(removePercentage2);
        trade.redeemTTF();
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to vault failed");
        emit TransferToVault(ethPoolAddress, protocolVaultAddress, _amount);
        return true;
    }

    /*
     * Notice: Triggers to occur in the range of 30 - >:
     * 1. feedPool() : _newPercent of Eth Pool is transferred to Vault
     */
    function processMoreThanValue4() internal returns (bool) {
        (uint256 _totalBalance,uint256 _percent, ) = price.getTaumPrice(0);
        uint256 _newPercent = _percent.sub(protocolVaultPercentage);
        uint256 _amount = _totalBalance.mul(_newPercent).div(10**20);
        bool _success = protocolVault.feedPool(_amount);
        require(_success, "Transfer to pool failed");
        emit TransferToETHPool(protocolVaultAddress, ethPoolAddress, _amount);
        return true;
    }
}
