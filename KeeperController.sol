// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./chainlink/KeeperCompatibleInterface.sol";
import "./interfaces/IBuyComponents.sol";
import "./interfaces/IEthereumVault.sol";
import "./interfaces/IWeth.sol";
import "./chainlink/IKeepRegistry.sol";
import "./interfaces/IPrice.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract KeeperController is KeeperCompatibleInterface {
    using SafeMath for uint256;

/* ================ State Variables ================== */

    // address of chainlink KeeperRegistry Contract 
    //address constant KEEPER_ADDRESS = 0x4Cb093f226983713164A62138C3F718A5b595F73;
    // address of link token
    address private linkToken;
    // address of contract creator
    address public owner;
    // address of manager
    address public manager;
    // chainlink keeper id of taum token contract 
    uint256 public taumFeeKeeperId;
    // chainlink keeper id of otta token contract
    uint256 public ottaLockKeeperId;
    // chainlink keeper id of gradualTaum  contract
    uint256 public gradualKeeperId;
    // chainlink keeper id of ethereum pool contract
    uint256 public ethPoolKeeperId;
    // chainlink keeper id of this contract
    uint256 public selfKeeperId;
    // chainlink keeper id of price contract
    uint256 public priceKeeperId;
    // set status of eth vault 
    bool public isEthVaultSetted = false;
    // importing chainlink keeper methods
    IKeepRegistry private keeper;
    // importing buyer contract methods
    IBuyComponents private buyer;
    // importing ethereum vault methods
    IEthereumVault private ethVault;
    // importing wrapped ether methods
    IWeth private weth;
    // importing price contract methods
    IPrice private price;

    struct KeeperBalances{
        uint96 minBalance;
        uint96 currentBalance;
        uint96 requirement;
    }

    mapping(uint256 => KeeperBalances) keeperBalancesMap;

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
        address _keeperRegistryAddress
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        keeper = IKeepRegistry(_keeperRegistryAddress);
        require(_weth != address(0));
        weth = IWeth(_weth);
        require(_linkToken != address(0));
        linkToken = _linkToken;
    }
/* ================ Functions ================== */
/* ================ Public Functions ================== */
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }

    /*
     * Notice: Setting chainlink keeper id's
     * Params:
     * '_taumFeeKeeperId' keeper id of taum token contract 
     * '_ottaLockKeeperId' keeper id of otta token contract 
     * '_gradualKeeperId' keeper id of gradualTaum token contract 
     * '_ethPoolKeeperId' keeper id of ethereum pool contract
     * '_priceKeeperId' keeper id of price contract
     * '_selfKeeperId' keeper id of this contract  
     * '_componentPriceKeeperId' keeper id of component price contract
     */
    function setKeeperIDs(
        uint256 _taumFeeKeeperId,
        uint256 _ottaLockKeeperId,
        uint256 _gradualKeeperId,
        uint256 _ethPoolKeeperId,
        uint256 _priceKeeperId,
        uint256 _selfKeeperId
    ) public {
        require(msg.sender == owner, "only owner");
        require(_taumFeeKeeperId != 0);
        taumFeeKeeperId = _taumFeeKeeperId;
        require(_ottaLockKeeperId != 0);
        ottaLockKeeperId = _ottaLockKeeperId;
        require(_gradualKeeperId != 0);
        gradualKeeperId = _gradualKeeperId;
        require(_ethPoolKeeperId != 0);
        ethPoolKeeperId = _ethPoolKeeperId;
        require(_priceKeeperId != 0);
        priceKeeperId = _priceKeeperId;
        require(_selfKeeperId != 0);
        selfKeeperId = _selfKeeperId;
    }
    
    function setBuyer(
        address _buyerAddress
    ) public onlyOwner {
        require(_buyerAddress != address(0), "zero address");
        buyer = IBuyComponents(_buyerAddress);
    }
    
    function setEthVaultAddress(
        address _ethVaultAddress
    ) public onlyOwner {
        require(isEthVaultSetted == false, "Already Setted");
        require(_ethVaultAddress != address(0), "zero address");
        ethVault = IEthereumVault(_ethVaultAddress);
        isEthVaultSetted = true;
    }
    
    function setPrice(
        address _priceAddress
    ) public onlyOwner {
        require(_priceAddress != address(0), "zero address");
        price = IPrice(_priceAddress);
    }

    
/* ================ Internal Functions ================== */

    /*
     * Notice: brings ether from ethereum vault
     * Param:
     * '_wethQuantity' Quantity of ether to bring
     */
    function bringEth(uint256 _wethQuantity) internal {
        address payable _payableThis = payable(address(this));
        ethVault.withdraw(_payableThis, _wethQuantity);
        weth.deposit{value: _wethQuantity}();
    }
     /*
     * Notice: this method buys link token
     * Param:
     * '_linkQuantity' Quantity of link token to swap
     * '_wethQuantity' Quantity of wrapped ether to swap with link token 
     */
    function buyLink(uint256 _linkQuantity, uint256 _wethQuantity) internal {
        bringEth(_wethQuantity);
        buyer.buyComponents(linkToken, _linkQuantity, _wethQuantity);
    }

    /*
     * Notice: this method reads minBalance and balance variables 
               from chainlink keepRegistry contract
               Calculating and comparing requirements
    * Returns: minBalances, balances and requirements for all keepers
    */
    function getVariables() internal
    {

        KeeperBalances memory _taumKeeper;
        _taumKeeper.minBalance = keeper.getMinBalanceForUpkeep(taumFeeKeeperId);
        (, , , _taumKeeper.currentBalance, , , ) = keeper.getUpkeep(taumFeeKeeperId);
        _taumKeeper.requirement = (_taumKeeper.minBalance*125)/100;
        keeperBalancesMap[taumFeeKeeperId] = _taumKeeper;

        KeeperBalances memory _ottaKeeper;
        _ottaKeeper.minBalance = keeper.getMinBalanceForUpkeep(ottaLockKeeperId);
        (, , , _ottaKeeper.currentBalance, , , ) = keeper.getUpkeep(ottaLockKeeperId);
        _ottaKeeper.requirement = (_ottaKeeper.minBalance*125)/100;
        keeperBalancesMap[ottaLockKeeperId] = _ottaKeeper;

        KeeperBalances memory _gradualKeeper;
        _gradualKeeper.minBalance = keeper.getMinBalanceForUpkeep(gradualKeeperId);
        (, , , _gradualKeeper.currentBalance, , , ) = keeper.getUpkeep(gradualKeeperId);
        _gradualKeeper.requirement = (_gradualKeeper.minBalance*125)/100;
        keeperBalancesMap[gradualKeeperId] = _gradualKeeper;

        KeeperBalances memory _ethPoolKeeper;
        _ethPoolKeeper.minBalance = keeper.getMinBalanceForUpkeep(ethPoolKeeperId);
        (, , , _ethPoolKeeper.currentBalance, , , ) = keeper.getUpkeep(ethPoolKeeperId);
        _ethPoolKeeper.requirement = (_ethPoolKeeper.minBalance*125)/100;
        keeperBalancesMap[ethPoolKeeperId] = _ethPoolKeeper;

        KeeperBalances memory _selfKeeper;
        _selfKeeper.minBalance = keeper.getMinBalanceForUpkeep(selfKeeperId);
        (, , , _selfKeeper.currentBalance, , , ) = keeper.getUpkeep(selfKeeperId);
        _selfKeeper.requirement = (_selfKeeper.minBalance*125)/100;
        keeperBalancesMap[selfKeeperId] = _selfKeeper;

        KeeperBalances memory _priceKeeper;
        _priceKeeper.minBalance = keeper.getMinBalanceForUpkeep(priceKeeperId);
        (, , , _priceKeeper.currentBalance, , , ) = keeper.getUpkeep(priceKeeperId);
        _priceKeeper.requirement = (_priceKeeper.minBalance*125)/100;
        keeperBalancesMap[priceKeeperId] = _priceKeeper;
        
        /*KeeperBalances memory _componentPriceKeeper;
        _componentPriceKeeper.minBalance = keeper.getMinBalanceForUpkeep(componentPriceKeeperId);
        (, , , _componentPriceKeeper.currentBalance, , , ) = keeper.getUpkeep(componentPriceKeeperId);
        _componentPriceKeeper.requirement = (_componentPriceKeeper.minBalance*125)/100;
        keeperBalancesMap[componentPriceKeeperId] = _componentPriceKeeper;*/

    }

    /*
     * Notice: this method buys link token as needed
                executes from chainlink keeper
     * Params: minBalances, balances and requirements of all keepers for buy link token.
     */
    function controller() internal {

        getVariables();
        uint256 _linkPrice = price.getLinkPrice();
        KeeperBalances memory _taum = keeperBalancesMap[taumFeeKeeperId];
        KeeperBalances memory _gradual = keeperBalancesMap[gradualKeeperId];
        KeeperBalances memory _ethPool = keeperBalancesMap[ethPoolKeeperId];
        KeeperBalances memory _otta = keeperBalancesMap[ottaLockKeeperId];
        KeeperBalances memory _self = keeperBalancesMap[selfKeeperId];
        KeeperBalances memory _price = keeperBalancesMap[priceKeeperId];
        //KeeperBalances memory _componentPrice = keeperBalancesMap[componentPriceKeeperId];

        if (_taum.currentBalance < _taum.requirement) {
            uint96 _linkQuantity = (_taum.minBalance * 2) - _taum.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _wethQuantity = _linkToBuy.mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(taumFeeKeeperId, _linkQuantity);
        }
        if (_gradual.currentBalance < _gradual.requirement) {
            uint96 _linkQuantity = (_gradual.minBalance * 2) - _gradual.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _wethQuantity = _linkToBuy.mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(gradualKeeperId, _linkQuantity);
        }
        if (_ethPool.currentBalance < _ethPool.requirement) {
            uint96 _linkQuantity = (_ethPool.minBalance * 2) - _ethPool.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _wethQuantity = _linkToBuy.mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(ethPoolKeeperId, _linkQuantity);
        }
        if (_otta.currentBalance < _otta.requirement) {
            uint96 _linkQuantity = (_otta.minBalance * 2) - _otta.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _wethQuantity = _linkToBuy.mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(ottaLockKeeperId, _linkQuantity);
        }
        if (_self.currentBalance< _self.requirement) {
            uint96 _linkQuantity = (_self.minBalance * 2) - _self.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _wethQuantity = _linkToBuy.mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(selfKeeperId, _linkQuantity);
        }
        if (_price.currentBalance < _price.requirement) {
            uint96 _linkQuantity = (_price.minBalance * 2) - _price.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _wethQuantity = _linkToBuy.mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(priceKeeperId, _linkQuantity);
        }
        /*if (_componentPrice.currentBalance < _componentPrice.requirement) {
            uint96 _linkQuantity = (_componentPrice.minBalance * 2) - _componentPrice.currentBalance;
            uint256 _linkToBuy = uint256(_linkQuantity);
            uint256 _wethQuantity = _linkToBuy.mul(_linkPrice).div(10**18);
            buyLink(_linkToBuy, _wethQuantity);
            keeper.addFunds(componentPriceKeeperId, _linkQuantity);
        }*/
    }
/* ================ External Functions ================== */

    /*
     * Notice: chainlink keeper method. It controls boolean value for execute perfomUpkeep
     */
    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        getVariables();
        upkeepNeeded =
            keeperBalancesMap[taumFeeKeeperId].currentBalance < keeperBalancesMap[taumFeeKeeperId].requirement ||
            keeperBalancesMap[ottaLockKeeperId].currentBalance < keeperBalancesMap[ottaLockKeeperId].requirement ||
            keeperBalancesMap[gradualKeeperId].currentBalance < keeperBalancesMap[gradualKeeperId].requirement||
            keeperBalancesMap[ethPoolKeeperId].currentBalance < keeperBalancesMap[ethPoolKeeperId].requirement ||
            keeperBalancesMap[priceKeeperId].currentBalance < keeperBalancesMap[priceKeeperId].requirement ||
            keeperBalancesMap[selfKeeperId].currentBalance < keeperBalancesMap[selfKeeperId].requirement;
            //keeperBalancesMap[componentPriceKeeperId].currentBalance < keeperBalancesMap[componentPriceKeeperId].requirement;
        performData = checkData;
    }

    /*
     * Notice: chainlink keeper method. It executes controller method
     */
    function performUpkeep(bytes calldata performData) external override {
        controller();
        performData;
    }
}