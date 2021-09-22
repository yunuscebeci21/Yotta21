// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {IWeth} from "./interfaces/IWeth.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IEthereumVault.sol";
import {IGradualTaum} from "./interfaces/IGradualTaum.sol";

/// @title Uniswap Adapter
/// @author Yotta21
contract EthereumVault is IEthereumVault {

    /*============ State Variables ================ */

    // Address of contract creater
    address private owner;
    // address of manager
    address public manager;
    // Address of Pool Token Adapter
    address private poolTokenAdapterAddress;
    // Address of Gradual Reduction Contract
    address private gradualTaumAddress;
    // Address of Ethereum Pool Contact
    address payable public ethPool;
    // Address of wrapper ether
    address private wethAddress;
    // address of taum address
    address private taumAddress;
    // address of price contract
    address public priceAddress;
    // address of component price contract
    address public componentPriceAddress;
    // address of keeper controller
    address public keeperControllerAddress;
    // set state of eth pool
    bool public isEthPoolSetted = false;
    // importing gradual taum methods
    IGradualTaum private gradualTaum;
    // Importing wrapped ether methods
    IWeth private weth;

    /*============ Modifiers ================ */
    /*
     * Throws if the sender is not one of poolTokenAdapter, taumToken,
     *  priceAddress or keeperControllerAddres
     */
    modifier onlyProtocolContracts() {
        require(
            (
                msg.sender == taumAddress ||
                msg.sender == priceAddress ||
                msg.sender == keeperControllerAddress),
            "Only Protocol"
        );
        _;
    }
    /*
     * Throws if the sender is not gradual reduction contract
     */
    modifier onlyGradual() {
        require(msg.sender == gradualTaumAddress, "Only Gradual Taum");
        _;
    }
    /*
     * Throws if the sender is not an owner of this contract
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /*============ Constructor ================ */
    constructor(
        address _manager,
        address _poolTokenAdapter,
        address _weth,
        address _taumAddress,
        address _priceAddress,
        address _keeperControllerAddress
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_poolTokenAdapter != address(0), "zero address");
        poolTokenAdapterAddress = _poolTokenAdapter;
        require(_weth != address(0), "zero address");
        wethAddress = _weth;
        weth = IWeth(wethAddress);
        require(_taumAddress != address(0), "zero address");
        taumAddress = _taumAddress;
        require(_priceAddress != address(0), "zero address");
        priceAddress = _priceAddress;
        keeperControllerAddress = _keeperControllerAddress;
    }

    /*================= Functions=================*/
    /*================= Public Functions=================*/
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
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
        priceAddress = _priceAddress;
        return _priceAddress;
    }
    
    function setGradual(address _gradualAddress)
        public
        onlyOwner
        returns (address newGradualAddress)
    {
        require(_gradualAddress != address(0), "zero address");
        gradualTaumAddress = _gradualAddress;
        gradualTaum = IGradualTaum(gradualTaumAddress);
        return _gradualAddress;
    }
    
    function setComponentPrice(address _componentPriceAddress)
        public
        onlyOwner
        returns (address newComponentPriceAddress)
    {
        require(_componentPriceAddress != address(0), "zero address");
        componentPriceAddress = _componentPriceAddress;
        return _componentPriceAddress;
    }
    /*
     * Notice: Setting ethereum pool address only once
     * Return: 
     * '_ethereumPoolAddress' The new ethereum pool address.
     */
    function setEthPool(address payable _ethPoolAddress) public onlyOwner returns(address _newEthPoolAddress){
        require(_ethPoolAddress != address(0),"zero address");
        require(!isEthPoolSetted,"Already Setted");
        ethPool = _ethPoolAddress;
        isEthPoolSetted = true;
        emit EthPoolSetted(ethPool);
        return(ethPool);
        
    }

    /*================= External Functions=================*/
    receive() external payable{}
    /*
     * Notice: This method can callable from Yotta Token contract
     *         It will send calculated withdrawal quantity of ETH to user
     * Params:
     * '_userAddress' The user address
     * '_withdrawPrice' The amount of withdraw
     */
    function withdraw(address payable _userAddress, uint256 _withdrawPrice)
        external
        override
        onlyProtocolContracts
        returns (bool state)
    {
        weth.withdraw(_withdrawPrice);
        _userAddress.transfer(_withdrawPrice);
        gradualTaum.calculateProtocolPercent();

        emit WithDrawtoUser(_userAddress, _withdrawPrice);
        return (true);
    }

    /*
     * Notice: It is for gradual reduction contract
     *         Sends wrapped ether to Ethereum Pool, if needs.
     * Param:
     * '_amount' amount to be transferred to the ethereum pool
     */
    function feedPool(uint256 _amount)
        external
        payable
        override
        onlyGradual
        returns (bool)
    {
        bool _successTransfer = weth.transfer(ethPool, _amount);
        require(_successTransfer, "Transfer failed.");
        emit PoolFeeded(ethPool, _amount);

        return true;
    }
}
