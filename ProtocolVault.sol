// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWeth} from "./interfaces/IWeth.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IProtocolVault} from "./interfaces/IProtocolVault.sol";
import {IEthereumPool} from "./interfaces/IEthereumPool.sol";
import {IProtocolGradual} from "./interfaces/IProtocolGradual.sol";

/// @title ProtocolVault
/// @author Yotta21
contract ProtocolVault is IProtocolVault {

    /* ============ Events ================ */
    
    event ManagerSetted(address _manager);
    event PriceSetted(address _priceAddress);
    event KeeperControllerSetted(address _keeperAddress);
    event ProtocolGradualSetted(address _protocolGradualAddress);
    event EthPoolSetted(address _ethPoolAddress);

    /*============ State Variables ================ */

    // Address of contract creater
    address public owner;
    // address of manager
    address public manager;
    // Address of Gradual Reduction Contract
    address public protocolGradualAddress;
    // Address of Ethereum Pool Contact
    address public ethPoolAddress;
    // Address of wrapper ether
    address public wethAddress;
    // address of taum address
    address public taumAddress;
    // address of price contract
    address public priceAddress;
    // address of keeper controller
    address public keeperControllerAddress;
    // set state of protocol vault
    bool public isEthPoolSetted;
    bool public isManagerSetted;
    bool public isPriceSetted;
    bool public isKeeperControllerSetted;
    bool public isProtocolGradualSetted;
    // importing gradual taum methods
    IProtocolGradual public protocolGradual;
    // Importing wrapped ether methods
    IWeth public weth;
    // importing eth pool methods
    IEthereumPool public ethPool;

    /*============ Modifiers ================ */
    /*
     * Throws if the sender is not one of poolTokenAdapter, taumToken,
     *  priceAddress or keeperControllerAddres
     */
    modifier onlyProtocolContracts() {
        require(
            (
                msg.sender == taumAddress ||
                msg.sender == keeperControllerAddress ||
                msg.sender == protocolGradualAddress),
            "Only Protocol"
        );
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
        address _weth,
        address _taumAddress
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_weth != address(0), "zero address");
        wethAddress = _weth;
        weth = IWeth(wethAddress);
        require(_taumAddress != address(0), "zero address");
        taumAddress = _taumAddress;
        
    }

    /*================= Functions=================*/
    /*================= Public Functions=================*/

    /* Notice: Setting manager address methods
     * Params:
     * '_manager' The manager address.
     */
    function setManager(address _manager) public onlyOwner returns(address){
        require(!isManagerSetted,"Already Setted");
        require(_manager != address(0),"zero address");
        isManagerSetted = true;
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
        require(!isPriceSetted,"Already Setted");
        require(_priceAddress != address(0),"zero address");
        isPriceSetted = true;
        priceAddress = _priceAddress;
        emit PriceSetted(priceAddress);
        return _priceAddress;
    }

    /*
     * Notice: Setting keeper controller contract address only once
     * Return: 
     * '_keeperAddress' The new keeper controller contract address.
     */
    function setKeeperController(address _keeperAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isKeeperControllerSetted,"Already Setted");
        require(_keeperAddress != address(0),"zero address");
        isKeeperControllerSetted = true;
        keeperControllerAddress = _keeperAddress;
        emit KeeperControllerSetted(keeperControllerAddress);
        return keeperControllerAddress;
    }
    
    /*
     * Notice: Setting protocol gradual address only once
     * Return: 
     * '_protocolGradualAddress' The new protocol gradual address.
     */
    function setProtocolGradual(address _protocolGradualAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isProtocolGradualSetted,"Already Setted");
        require(_protocolGradualAddress != address(0),"zero address");
        isProtocolGradualSetted = true;
        protocolGradualAddress = _protocolGradualAddress;
        protocolGradual = IProtocolGradual(protocolGradualAddress);
        emit ProtocolGradualSetted(protocolGradualAddress);
        return protocolGradualAddress;
    }
    
    /*
     * Notice: Setting ethereum pool address only once
     * Return: 
     * '_ethereumPoolAddress' The new ethereum pool address.
     */
    function setEthPool(address payable _ethPoolAddress) public onlyOwner returns(address){
        require(!isEthPoolSetted,"Already Setted");
        require(_ethPoolAddress != address(0),"zero address");
        isEthPoolSetted = true;
        ethPoolAddress = _ethPoolAddress;
        ethPool = IEthereumPool(_ethPoolAddress);
        emit EthPoolSetted(ethPoolAddress);
        return(ethPoolAddress);
        
    }

    /*================= External Functions=================*/
    receive() external payable{
        require(msg.sender == wethAddress, "only weth");
    }

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

        emit WithDrawtoUser(_userAddress, _withdrawPrice);
        return (true);
    }

    /*
     * Notice: It is for protocol gradual contract
     * Params:
     * '_amount' The transfer amount
     */
    function feedPool(uint256 _amount)
        external
        override
        returns (bool)
    {
        require(msg.sender == protocolGradualAddress, "Only Gradual Taum");
        bool _successTransfer = weth.transfer(ethPoolAddress, _amount);
        require(_successTransfer, "Transfer failed.");
        ethPool.addLimit(_amount);
        emit PoolFeeded(ethPoolAddress, _amount);

        return true;
    }
}
