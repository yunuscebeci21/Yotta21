// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IEthereumPool.sol";
import "./interfaces/IIndexLiquidityPool.sol";
import "./interfaces/IEthereumVault.sol";
import "./interfaces/IUniswapV2Adapter.sol";
import "./interfaces/IBuyComponents.sol";
import "./chainlink/KeeperCompatibleInterface.sol";
import {IGradualTaum} from "./interfaces/IGradualTaum.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IPrice} from "./interfaces/IPrice.sol";

contract GradualTaum is IGradualTaum, KeeperCompatibleInterface {
    using SafeMath for uint256;

    /*================== Variables ===================*/

    // address of owner
    address public owner;
    // address of manager 
    address public manager;
    // address of ethereum pool contract
    address payable public ethPoolAddress;
    // address of index pool contract
    address public indexPoolAddress;
    // address of ethereum vault contract
    address public ethVaultAddress;
    // address of uniswap adapter
    address public uniswapV2AdapterAddress;
    // address of ERC20 weth
    address private wethAddress;
    // constant value1
    uint256 private constant VALUE1 = 0 * 10 ** 18;
    // constant value2
    uint256 private constant VALUE2 = 5 * 10 ** 18;
    // constant value3
    uint256 private constant VALUE3 = 10 * 10 ** 18;
    // constant value4
    uint256 private constant VALUE4 = 20 * 10 ** 18;
    // constant value5
    uint256 private constant VALUE5 = 30 * 10 ** 18;
    // vault set status
    //bool public isVaultSetted = false;
    bool public isEthPoolSetted = false;
    // importing Eth Pool Token Index Adapter contract interface as buyer (call redeemIndex function)
    IBuyComponents private buyer;
    // importing Uniswap Adapter contract interface as uniAdapter (call decreaseCollect, collectFromUni functions)
    IUniswapV2Adapter private uniV2Adapter;
    // importing Ethereum Vault contract interface as ethVault (call feedPool function)
    IEthereumVault private ethVault;
    // importing Ethereum Pool contract interface as ethPool (call feedVault function)
    IEthereumPool private ethPool;
    // importing Index Liquidity Pool contract interface as indexPool (call getIndexes)
    IIndexLiquidityPool private indexPool;
    // importing Price contract interface as price (call getNftAmount function)
    IPrice private price;
    // importing Wrapped Ethereum
    ERC20 private weth;

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
        address _ethVaultAddress,
        address _indexPoolAddress,
        address _uniswapV2AdapterAddress,
        address _buyerAddress,
        address _wethAddress,
        address _priceAddress
    )  {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_ethVaultAddress != address(0), "zero address");
        ethVaultAddress = _ethVaultAddress;
        ethVault = IEthereumVault(ethVaultAddress);
        require(_indexPoolAddress != address(0), "zero address");
        indexPoolAddress = _indexPoolAddress;
        indexPool = IIndexLiquidityPool(indexPoolAddress);
        require(_uniswapV2AdapterAddress != address(0), "zero address");
        uniswapV2AdapterAddress = _uniswapV2AdapterAddress;
        uniV2Adapter = IUniswapV2Adapter(uniswapV2AdapterAddress);
        require(_buyerAddress != address(0), "zero address");
        buyer = IBuyComponents(_buyerAddress);
        require(_wethAddress != address(0), "zero address");
        wethAddress = _wethAddress;
        weth = ERC20(wethAddress);
        require(_priceAddress != address(0), "zero address");
        price = IPrice(_priceAddress);
    }

    /*=============== Public Functions =====================*/
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }
    /*
     * Notice: Setting vault - only once
     */
    function setEthPool(address payable _ethPoolAddress)
        public
        onlyOwner
        returns (address _newEthPoolAddress)
    {
        require(_ethPoolAddress != address(0), "zero address");
        require(!isEthPoolSetted, "Already Setted");
        ethPoolAddress = _ethPoolAddress;
        ethPool = IEthereumPool(ethPoolAddress);
        isEthPoolSetted = true;
        emit EthPoolSetted(ethPoolAddress);
        return (ethPoolAddress);
    }

    function setPrice(address _priceAddress)
        public
        onlyOwner
        returns (address newPriceAddress)
    {
        require(_priceAddress != address(0), "zero address");
        price = IPrice(_priceAddress);
        return _priceAddress;
    }
    
    function setBuyer(address _buyerAddress)
        public
        onlyOwner
        returns (address newBuyerAddress)
    {
        require(_buyerAddress != address(0), "zero address");
        buyer = IBuyComponents(_buyerAddress);
        return _buyerAddress;
    }
    
    

    /*=============== External Functions =====================*/

    /*
     * Notice:  Chainlink Keeper method
     */
    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (,uint256 _percent,) = price.getTaumPrice();
        upkeepNeeded =
            (_percent >= VALUE1 || _percent <= VALUE2) ||
            (_percent > VALUE2 || _percent <= VALUE3) ||
            (_percent > VALUE3 || _percent <= VALUE4) ||
            (_percent > VALUE5);
        performData = checkData;
    }

    /*
     * Notice:  Chainlink Keeper method calls vaultPercentOfTotal method
     */
    function performUpkeep(bytes calldata performData) external override {
        vaultPercentOfTotal();
        performData;
    }

    function emergencyFunction() external onlyOwner {
        uniV2Adapter.removeLiquidity(100);
        buyer.redeemIndex();
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to vault failed");
        emit TransferToVault(ethPoolAddress, ethVaultAddress, _amount);
    }

    /*=============== Internal Functions =====================*/
    /*
     * Notice: The range of percent is determined and the related internal function is triggered
     */
    function vaultPercentOfTotal() internal {
        (,uint256 _percent,) = price.getTaumPrice();
        if (_percent >= VALUE1 || _percent <= VALUE2) {
            processValue1ToValue2();
        } else if (_percent > VALUE2 || _percent <= VALUE3) {
            processValue2ToValue3();
        } else if (_percent > VALUE3 || _percent <= VALUE4) {
            processValue3ToValue4();
        } else if (_percent > VALUE5) {
            processMoreThanValue5();
        }
    }

    /*
     * Notice: Triggers to occur in the range of 0 - 5:
     * 1. decreaseCollect() : 100% of NFT is withdrawn with fees
     * 2. redeemIndex() : Existing indexes are reedem
     * 3. feedVault() : 100% of Eth Pool is transferred to Vault
     */
    function processValue1ToValue2() internal returns (bool status) {
        uniV2Adapter.removeLiquidity(100);
        buyer.redeemIndex();
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to vault failed");
        emit TransferToVault(ethPoolAddress, ethVaultAddress, _amount);
        return true;
    }

    /*
     * Notice: Triggers to occur in the range of 5 - 10:
     * 1. decreaseCollect() : 50% of NFT is withdrawn with fees
     * 2. redeemIndex() : Existing indexes are reedem
     * 3. feedVault() : 100% of Eth Pool is transferred to Vault
     */
    function processValue2ToValue3() internal returns (bool) {
        uniV2Adapter.removeLiquidity(50);
        buyer.redeemIndex();
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to vault failed");
        emit TransferToVault(ethPoolAddress, ethVaultAddress, _amount);
        return true;
    }

    /*
     * Notice: Triggers to occur in the range of 10 - 20:
     * 1. collectFromUni() : fee of NFT is withdrawn
     * 2. redeemIndex() : Existing indexes are reedem
     * 3. feedVault() : 100% of Eth Pool is transferred to Vault
     */
    function processValue3ToValue4() internal returns (bool) {
        uniV2Adapter.removeLiquidity(15);
        buyer.redeemIndex();
        uint256 _amount = weth.balanceOf(ethPoolAddress);
        bool _success = ethPool.feedVault(_amount);
        require(_success, "Transfer to vault failed");
        emit TransferToVault(ethPoolAddress, ethVaultAddress, _amount);
        return true;
    }

    /*
     * Notice: Triggers to occur in the range of 30 - >:
     * 1. feedPool() : _newPercent of Eth Pool is transferred to Vault
     */
    function processMoreThanValue5() internal returns (bool) {
        (uint256 _totalBalance,uint256 _percent, ) = price.getTaumPrice();
        uint256 _newPercent = _percent.sub(25 * 10 ** 18);
        uint256 _amount = _totalBalance.mul(_newPercent).div(100 * 10 ** 18);
        bool _success = ethVault.feedPool(_amount);
        require(_success, "Transfer to pool failed");
        emit TransferToETHPool(ethVaultAddress, ethPoolAddress, _amount);
        return true;
    }
}
