// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITradeComponents} from "./interfaces/ITradeComponents.sol";
import {IProtocolVault} from "./interfaces/IProtocolVault.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IKeepRegistry} from "./chainlink/IKeepRegistry.sol";
import {IPrice} from "./interfaces/IPrice.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract KeeperController {

    using SafeMath for uint256;
    /* ================ Events ================== */
    
    event ManagerSetted(address _manager);
    event KeeperIDsSetted(uint256 _taumFeeKeeperId, uint256 _ottaLockKeeperId, uint256 _gradualKeeperId, uint256 _ethPoolKeeperId, uint256 _ttfPoolKeeperId, uint256 _selfKeeperId);
    event TradeFromUniswapV2(address _tradeFromuniswapV2Address);
    event ProtocolVaultSetted(address _protocolVaultAddress);
    event PriceSetted(address _priceAddress);
    event KeeperRegistrySetted(address _keeperRegistryAddress);

    /* ================ State Variables ================== */

    // address of link token
    address public linkToken;
    // address of contract creator
    address public owner;
    // address of manager
    address public manager;
    // address of protocol vault
    address public protocolVaultAddress;
    // address of trade from UniswapV2
    address public tradeFromUniswapV2Address;
    // address of keeper registry
    address public keeperRegistryAddress;
    // maximum integer value
    uint256 public constant MAX_INT = 2**256 - 1;
    // chainlink keeper id of taum token contract 
    uint256 public taumFeeKeeperId;
    // chainlink keeper id of otta token contract
    uint256 public ottaLockKeeperId;
    // chainlink keeper id of protocol gradual  contract
    uint256 public gradualKeeperId;
    // chainlink keeper id of ethereum pool contract
    uint256 public ethPoolKeeperId;
    // chainlink keeper id of ttf pool contract
    uint256 public ttfPoolKeeperId;
    // chainlink keeper id of this contract
    uint256 public selfKeeperId;
    // for self keeper
    uint96 public selfKeeperRequirementPercentage;
    // for other keeper
    uint96 public keeperRequirementPercentage;
    // set status of this contract 
    //bool public isManagerSetted;
    bool public isKeeperIDsSetted;
    bool public isTradeFromUniswapV2Setted;
    bool public isProtocolVaultSetted;
    bool public isPriceSetted;
    // struct map of keepers
    mapping(uint256 => KeeperBalances) public keeperBalancesMap;
    // importing chainlink keeper methods
    IKeepRegistry private keeper;
    // importing buyer contract methods
    ITradeComponents private trade;
    // importing ethereum vault methods
    IProtocolVault private protocolVault;
    // importing wrapped ether methods
    IWeth private weth;
    // importing price contract methods
    IPrice private price;
    // info of Keepers
    struct KeeperBalances{
        uint96 minBalance;
        uint96 currentBalance;
        uint96 requirement;
    }
    
    /* ================= Modifiers ================= */

    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }


    /* ================ Constructor ================== */
    constructor(
        address _manager,
        address _weth,
        address _linkToken,
        address _keeperRegistryAddress,
        uint96 _selfKeeperRequirementPercentage,
        uint96 _keeperRequirementPercentage
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        keeper = IKeepRegistry(_keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
        require(_weth != address(0));
        weth = IWeth(_weth);
        require(_linkToken != address(0));
        linkToken = _linkToken;
        require(_selfKeeperRequirementPercentage != 0, "not zero");
        selfKeeperRequirementPercentage = _selfKeeperRequirementPercentage;
        require(_keeperRequirementPercentage != 0, "not zero");
        keeperRequirementPercentage = _keeperRequirementPercentage;
    }
    
    /* ================ Functions ================== */
    /* ================ Public Functions ================== */

    /*
     * Notice: Setting manager address
     * Params:
     * '_manager' The manager address
     */
    function setManager(address _manager) public onlyOwner returns(address){
        //require(!isManagerSetted, "Already setted");
        require(_manager != address(0), "zero address");
        //isManagerSetted = true;
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }

    /*
     * Notice: Setting chainlink keeper id's
     * Params:
     * '_taumFeeKeeperId' keeper id of taum token contract 
     * '_ottaLockKeeperId' keeper id of otta token contract 
     * '_gradualKeeperId' keeper id of protocol gradual contract 
     * '_ethPoolKeeperId' keeper id of ethereum pool contract
     * '_ttfPoolKeeperId' keeper id of ttf pool contract
     * '_selfKeeperId' keeper id of this contract  
     */
    function setKeeperIDs(
        uint256 _taumFeeKeeperId,
        uint256 _ottaLockKeeperId,
        uint256 _gradualKeeperId,
        uint256 _ethPoolKeeperId,
        uint256 _ttfPoolKeeperId,
        uint256 _selfKeeperId
    ) public onlyOwner returns(uint256,uint256,uint256,uint256,uint256,uint256){
        //require(!isKeeperIDsSetted, "Already setted");
        //isKeeperIDsSetted = true;
        require(_taumFeeKeeperId != 0);
        taumFeeKeeperId = _taumFeeKeeperId;
        require(_ottaLockKeeperId != 0);
        ottaLockKeeperId = _ottaLockKeeperId;
        require(_gradualKeeperId != 0);
        gradualKeeperId = _gradualKeeperId;
        require(_ethPoolKeeperId != 0);
        ethPoolKeeperId = _ethPoolKeeperId;
        require(_ttfPoolKeeperId != 0);
        ttfPoolKeeperId = _ttfPoolKeeperId;
        require(_selfKeeperId != 0);
        selfKeeperId = _selfKeeperId;
        emit KeeperIDsSetted(_taumFeeKeeperId, _ottaLockKeeperId, _gradualKeeperId, _ethPoolKeeperId, _ttfPoolKeeperId, _selfKeeperId);
        return (taumFeeKeeperId, ottaLockKeeperId, gradualKeeperId, ethPoolKeeperId, ttfPoolKeeperId, selfKeeperId);
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
        tradeFromUniswapV2Address = _tradeFromuniswapV2Address;
        trade = ITradeComponents(_tradeFromuniswapV2Address);
        emit TradeFromUniswapV2(tradeFromUniswapV2Address);
        return tradeFromUniswapV2Address;
    }
    
    /*
     * Notice: Setting protocol vault contract address
     * Params:
     * '_protocolVaultAddress' The protocol vault contract address
     */
    function setProtocolVault(
        address _protocolVaultAddress
    ) public onlyOwner returns(address){
        require(!isProtocolVaultSetted, "Already Setted");
        require(_protocolVaultAddress != address(0), "zero address");
        isProtocolVaultSetted = true;
        protocolVaultAddress = _protocolVaultAddress;
        protocolVault = IProtocolVault(protocolVaultAddress);
        emit ProtocolVaultSetted(protocolVaultAddress);
        return protocolVaultAddress;
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
     * Notice: Setting keeper registry contract address
     * Params:
     * '_keeperRegistryAddress' The keeper registry contract address
     */
    function setKeeperRegistry(
        address _keeperRegistryAddress
    ) public onlyOwner returns(address){
        keeper = IKeepRegistry(_keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
        emit KeeperRegistrySetted(keeperRegistryAddress);
        return keeperRegistryAddress;
    }

    /*
     * Notice: Setting keeper keeper percentage
     * Params:
     * '_selfKeeperRequirementPercentage' The self keeper percentage
     * '_keeperRequirementPercentage' The other keeper percentage
     */
    function setKeeperPercentage(
        uint96 _selfKeeperRequirementPercentage,
        uint96 _keeperRequirementPercentage
    ) public onlyOwner returns(uint96,uint96){
        require(_selfKeeperRequirementPercentage != 0, "not zero");
        selfKeeperRequirementPercentage = _selfKeeperRequirementPercentage;
        require(_keeperRequirementPercentage != 0, "not zero");
        keeperRequirementPercentage = _keeperRequirementPercentage;
        return (selfKeeperRequirementPercentage, keeperRequirementPercentage);
    }
    
    /*
     * Notice: KeeperRegistryAddress approve to link token
     */
    function approveLink() public onlyOwner {
        ERC20 _link = ERC20(linkToken);
        bool _success = _link.approve(keeperRegistryAddress, MAX_INT);
        require(_success, "Approve failed");
    }


    /* ================ External Functions ================== */

    receive() external payable{}

    
    /*
     * Notice: chainlink keeper method. It controls boolean value for execute perfomUpkeep
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData)
    {
        getVariables();
        upkeepNeeded =
            keeperBalancesMap[taumFeeKeeperId].currentBalance < keeperBalancesMap[taumFeeKeeperId].requirement ||
            keeperBalancesMap[ottaLockKeeperId].currentBalance < keeperBalancesMap[ottaLockKeeperId].requirement ||
            keeperBalancesMap[gradualKeeperId].currentBalance < keeperBalancesMap[gradualKeeperId].requirement||
            keeperBalancesMap[ethPoolKeeperId].currentBalance < keeperBalancesMap[ethPoolKeeperId].requirement ||
            keeperBalancesMap[ttfPoolKeeperId].currentBalance < keeperBalancesMap[ttfPoolKeeperId].requirement ||
            keeperBalancesMap[selfKeeperId].currentBalance < keeperBalancesMap[selfKeeperId].requirement;
        performData = checkData;
    }

    /*
     * Notice: chainlink keeper method. It executes controller method
     */
    function performUpkeep(bytes calldata performData) external {
        require((keeperBalancesMap[taumFeeKeeperId].currentBalance < keeperBalancesMap[taumFeeKeeperId].requirement ||
            keeperBalancesMap[ottaLockKeeperId].currentBalance < keeperBalancesMap[ottaLockKeeperId].requirement ||
            keeperBalancesMap[gradualKeeperId].currentBalance < keeperBalancesMap[gradualKeeperId].requirement||
            keeperBalancesMap[ethPoolKeeperId].currentBalance < keeperBalancesMap[ethPoolKeeperId].requirement ||
            keeperBalancesMap[ttfPoolKeeperId].currentBalance < keeperBalancesMap[ttfPoolKeeperId].requirement ||
            keeperBalancesMap[selfKeeperId].currentBalance < keeperBalancesMap[selfKeeperId].requirement), "not epoch");
        controller();
        performData;
    }
    
    /* ================ Internal Functions ================== */

    /*
     * Notice: brings ether from ethereum vault
     * Param:
     * '_wethQuantity' Quantity of ether to bring
     */
    function bringEth(uint256 _wethQuantity) public {
        address payable _payableThis = payable(address(this));
        protocolVault.withdraw(_payableThis, _wethQuantity);
        weth.deposit{value: _wethQuantity}();
        weth.transfer(tradeFromUniswapV2Address, _wethQuantity);
    }
     /*
     * Notice: this method buys link token
     * Param:
     * '_linkQuantity' Quantity of link token to swap
     * '_wethQuantity' Quantity of wrapped ether to swap with link token 
     */
    function buyLink(uint256 _linkQuantity, uint256 _wethQuantity) public {
        this.bringEth(_wethQuantity);
        trade.buyComponents(linkToken, _linkQuantity, _wethQuantity);
        trade.residualWeth();
    }

    /*
     * Notice: this method reads minBalance and balance variables 
               from chainlink keepRegistry contract
               Calculating and comparing requirements
    * Returns: minBalances, balances and requirements for all keepers
    */
    function getVariables() public
    {

        KeeperBalances memory _taumKeeper;
        _taumKeeper.minBalance = keeper.getMinBalanceForUpkeep(taumFeeKeeperId);
        (, , , _taumKeeper.currentBalance, , , ) = keeper.getUpkeep(taumFeeKeeperId);
        _taumKeeper.requirement = (_taumKeeper.minBalance*keeperRequirementPercentage)/100;
        keeperBalancesMap[taumFeeKeeperId] = _taumKeeper;

        KeeperBalances memory _ottaKeeper;
        _ottaKeeper.minBalance = keeper.getMinBalanceForUpkeep(ottaLockKeeperId);
        (, , , _ottaKeeper.currentBalance, , , ) = keeper.getUpkeep(ottaLockKeeperId);
        _ottaKeeper.requirement = (_ottaKeeper.minBalance*keeperRequirementPercentage)/100;
        keeperBalancesMap[ottaLockKeeperId] = _ottaKeeper;

        KeeperBalances memory _gradualKeeper;
        _gradualKeeper.minBalance = keeper.getMinBalanceForUpkeep(gradualKeeperId);
        (, , , _gradualKeeper.currentBalance, , , ) = keeper.getUpkeep(gradualKeeperId);
        _gradualKeeper.requirement = (_gradualKeeper.minBalance*keeperRequirementPercentage)/100;
        keeperBalancesMap[gradualKeeperId] = _gradualKeeper;

        KeeperBalances memory _ethPoolKeeper;
        _ethPoolKeeper.minBalance = keeper.getMinBalanceForUpkeep(ethPoolKeeperId);
        (, , , _ethPoolKeeper.currentBalance, , , ) = keeper.getUpkeep(ethPoolKeeperId);
        _ethPoolKeeper.requirement = (_ethPoolKeeper.minBalance*keeperRequirementPercentage)/100;
        keeperBalancesMap[ethPoolKeeperId] = _ethPoolKeeper;

        KeeperBalances memory _ttfPoolKeeper;
        _ttfPoolKeeper.minBalance = keeper.getMinBalanceForUpkeep(ttfPoolKeeperId);
        (, , , _ttfPoolKeeper.currentBalance, , , ) = keeper.getUpkeep(ttfPoolKeeperId);
        _ttfPoolKeeper.requirement = (_ttfPoolKeeper.minBalance*keeperRequirementPercentage)/100;
        keeperBalancesMap[ttfPoolKeeperId] = _ttfPoolKeeper;

        KeeperBalances memory _selfKeeper;
        _selfKeeper.minBalance = keeper.getMinBalanceForUpkeep(selfKeeperId);
        (, , , _selfKeeper.currentBalance, , , ) = keeper.getUpkeep(selfKeeperId);
        _selfKeeper.requirement = (_selfKeeper.minBalance*selfKeeperRequirementPercentage)/100;
        keeperBalancesMap[selfKeeperId] = _selfKeeper;

    }

    /*
     * Notice: this method buys link token as needed
                executes from chainlink keeper
     * Params: minBalances, balances and requirements of all keepers for buy link token.
     */
    function controller() public {

        getVariables();
        uint256 _linkPrice = price.getLinkPrice();
        KeeperBalances memory _taum = keeperBalancesMap[taumFeeKeeperId];
        KeeperBalances memory _gradual = keeperBalancesMap[gradualKeeperId];
        KeeperBalances memory _ethPool = keeperBalancesMap[ethPoolKeeperId];
        KeeperBalances memory _otta = keeperBalancesMap[ottaLockKeeperId];
        KeeperBalances memory _ttfPool = keeperBalancesMap[ttfPoolKeeperId];
        KeeperBalances memory _self = keeperBalancesMap[selfKeeperId];

        if (_taum.currentBalance < _taum.requirement) {
            uint96 _linkQuantity = (_taum.minBalance * (keeperRequirementPercentage/100)) - _taum.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _preLinkToBuy = _linkToBuy.add(_linkToBuy.mul(10).div(100));
            uint256 _wethQuantity = (_preLinkToBuy).mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(taumFeeKeeperId, _linkQuantity);
        }
        if (_gradual.currentBalance < _gradual.requirement) {
            uint96 _linkQuantity = (_gradual.minBalance * (keeperRequirementPercentage/100)) - _gradual.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _preLinkToBuy = _linkToBuy.add(_linkToBuy.mul(10).div(100));
            uint256 _wethQuantity = (_preLinkToBuy).mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(gradualKeeperId, _linkQuantity);
        }
        if (_ethPool.currentBalance < _ethPool.requirement) {
            uint96 _linkQuantity = (_ethPool.minBalance * (keeperRequirementPercentage/100)) - _ethPool.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _preLinkToBuy = _linkToBuy.add(_linkToBuy.mul(10).div(100));
            uint256 _wethQuantity = (_preLinkToBuy).mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(ethPoolKeeperId, _linkQuantity);
        }
        if (_ttfPool.currentBalance < _ttfPool.requirement) {
            uint96 _linkQuantity = (_ttfPool.minBalance * (keeperRequirementPercentage/100)) - _ttfPool.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _preLinkToBuy = _linkToBuy.add(_linkToBuy.mul(10).div(100));
            uint256 _wethQuantity = (_preLinkToBuy).mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(ttfPoolKeeperId, _linkQuantity);
        }
        if (_otta.currentBalance < _otta.requirement) {
            uint96 _linkQuantity = (_otta.minBalance * (keeperRequirementPercentage/100)) - _otta.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _preLinkToBuy = _linkToBuy.add(_linkToBuy.mul(10).div(100));
            uint256 _wethQuantity = (_preLinkToBuy).mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(ottaLockKeeperId, _linkQuantity);
        }
        if (_self.currentBalance< _self.requirement) {
            uint96 _linkQuantity = (_self.minBalance * (selfKeeperRequirementPercentage/100)) - _self.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _preLinkToBuy = _linkToBuy.add(_linkToBuy.mul(10).div(100));
            uint256 _wethQuantity = (_preLinkToBuy).mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(selfKeeperId, _linkQuantity);
        }
    }

}