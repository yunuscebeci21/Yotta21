// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV2Router02} from "./uniswap/IUniswapV2Router02.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ITTFPool} from "./interfaces/ITTFPool.sol";
import {IUniswapPool} from "./interfaces/IUniswapPool.sol";
import {IUniswapV2Adapter} from "./interfaces/IUniswapV2Adapter.sol";
import {IPrice} from "./interfaces/IPrice.sol";
import {IWeth} from "./interfaces/IWeth.sol";

contract UniswapV2Adapter is IUniswapV2Adapter {
    using SafeMath for uint256;

    /*================== Events ===================*/

    event TTFPoolSetted(address _ttfPoolAddress);
    event PriceSetted(address _priceAddress);
    event ProtocolVaultSetted(address _protocolVaultAddress);
    event EthPoolSetted(address _ethPoolAddress);
    event ProtocolGradualSetted(address _protocolGradualAddress);

    /*================== State Variables ===================*/

    // address of contract creator
    address public owner;
    // address of manager
    address public manager;
    // address of weth address
    address public wethAddress;
    // address of ttf token
    address public ttf;
    // address of Router02 contract address
    address public router02Address;
    // address of ttf pool contract
    address public ttfPoolAdress;
    // address of protocol vault contract
    address public protocolVaultAddress;
    // address of ethereum pool contract
    address public ethPoolAddress;
    // address of protocol gradual contract
    address public protocolGradual;
    // transaction revert time
    uint256 public constant DEADLINE = 5 hours;
    // maximum integer value
    uint256 public constant MAX_INT = 2**256 - 1;
    // ttf's pool address after it was added to univ2
    address public ttfUniV2Address;
    // set status of this contract
    bool public isTTFPoolSetted;
    bool public isPriceSetted;
    bool public isProtocolVaultSetted;
    bool public isEthPoolSetted;
    bool public isProtocolGradualSetted;
    // importing UniswapV2Router02 contract interface
    IUniswapV2Router02 public router02;
    // importing TTFPool contract interface
    ITTFPool public ttfPool;
    // importing UniswapPool interface
    IUniswapPool public ttfUniV2;
    // importing Price contract interface
    IPrice public price;
    // importing Weth contract interface
    IWeth public weth;

    /* ================ Modifier ================== */

    /*
     * Throws if the sender is not owner or manager
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner or Manager");
        _;
    }

    /*=============== Constructor ========================*/
    constructor(
        address _manager,
        address _router02,
        address _weth,
        address _ttf,
        address _uniswapTtfPool
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_router02 != address(0), "zero address");
        router02 = IUniswapV2Router02(_router02);
        router02Address = _router02;
        require(_weth != address(0), "zero address");
        wethAddress = _weth;
        weth = IWeth(wethAddress);
        require(_ttf != address(0), "zero address");
        ttf = _ttf;
        require(_uniswapTtfPool != address(0), "zero address");
        ttfUniV2 = IUniswapPool(_uniswapTtfPool);
        ttfUniV2Address = _uniswapTtfPool;
    }

    /*================== Functions =====================*/
    /*================== Public Functions =====================*/

    /* Notice: Setting manager address
     * Params:
     * '_manager' The manager address.
     */
    /*function setManager(address _manager) public onlyOwner returns (address) {
        require(_manager != address(0), "zero address");
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }*/

    /* Notice: Setting ttf pool address
     * Params:
     * '_ttfPoolAddress' The ttf pool contract address.
     */
    function setTTFPool(address _ttfPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isTTFPoolSetted, "Already setted");
        require(_ttfPoolAddress != address(0), "zero address");
        isTTFPoolSetted = true;
        ttfPoolAdress = _ttfPoolAddress;
        ttfPool = ITTFPool(ttfPoolAdress);
        emit TTFPoolSetted(ttfPoolAdress);
        return (ttfPoolAdress);
    }

    /* Notice: Setting price contract address
     * Params:
     * '_priceAddress' The price contract address.
     */
    function setPrice(address _priceAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isPriceSetted, "Already setted");
        require(_priceAddress != address(0),"zero address");
        isPriceSetted = true;
        price = IPrice(_priceAddress);
        emit PriceSetted(_priceAddress);
        return (_priceAddress);
    }

    /* Notice: Setting protocol vault contract address
     * Params:
     * '_protocolVaultAddress' The protocol vault contract address.
     */
    function setProtocolVault(address _protocolVaultAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isProtocolVaultSetted, "Already setted");
        require(_protocolVaultAddress != address(0), "zero address");
        isProtocolVaultSetted = true;
        protocolVaultAddress = _protocolVaultAddress;
        emit ProtocolVaultSetted(protocolVaultAddress);
        return (protocolVaultAddress);
    }

    /* Notice: Setting ethereum pool address
     * Params:
     * '_ethPoolAddress' The ethereum pool address.
     */
    function setEthPool(address _ethPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isEthPoolSetted, "Already setted");
        require(_ethPoolAddress != address(0), "zero address");
        ethPoolAddress = _ethPoolAddress;
        isEthPoolSetted = true;
        emit EthPoolSetted(ethPoolAddress);
        return (ethPoolAddress);
    }

    /* Notice: Setting protocol gradual address
     * Params:
     * '_protocolGradualAddress' The protocol gradual address.
     */
    function setProtocolGradual(address _protocolGradualAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isProtocolGradualSetted, "Already setted");
        require(_protocolGradualAddress != address(0), "zero address");
        protocolGradual = _protocolGradualAddress;
        isProtocolGradualSetted = true;
        emit ProtocolGradualSetted(protocolGradual);
        return (protocolGradual);
    }

    /*================== External Functions =====================*/

    /* Notice: Up to MAX_INT, router02 address is approved to weth, ttf, ttfUniV2
     */
    function approveTokens() external onlyOwner {
        ERC20 _weth = ERC20(wethAddress);
        bool success = _weth.approve(router02Address, MAX_INT);
        require(success, "weth approve error");
        ERC20 _ttf = ERC20(ttf);
        bool success2 = _ttf.approve(router02Address, MAX_INT);
        require(success2, "Index approve error");
        ERC20 _ttfPool = ERC20(ttfUniV2Address);
        bool success3 = _ttfPool.approve(router02Address, MAX_INT);
        require(success3, "Index approve error");
    }
    
    /* Notice: Ttf transfers to this contract to add to UniswapV2 pool
     */
    function bringTTFsFromPool() external override returns (bool) {
        require(msg.sender == ethPoolAddress, "only ethereum pool");
        ttfPool.sendTTF();
        return true;
    }

    /* Notice: It is added to the UniiswapV2 pool as 50% ttf and 50% weth.
     *         If weth remains, it will be transferred to the protocol vault.
     *         If the remaining ttf is transferred to the ttf pool.   
     */
    function addLiquidity() external override returns (bool) {
        ERC20 _ttf = ERC20(ttf);
        ERC20 _weth = ERC20(wethAddress);
        uint256 _ttfPrice = price.getTtfPrice();
        uint256 _ttfAmount = (_ttf.balanceOf(address(this))).mul(_ttfPrice).div(
            10**18
        );
        uint256 _wethAmount = (_weth.balanceOf(address(this)));
        uint256 _ttfAmountDesired;
        uint256 _wethAmountDesired;
        if (_wethAmount == _ttfAmount) {
            _wethAmountDesired = _wethAmount;
            _ttfAmountDesired = _ttf.balanceOf(address(this));
        } else if (_wethAmount > _ttfAmount) {
            _wethAmountDesired = _ttfAmount;
            _ttfAmountDesired = _ttf.balanceOf(address(this));
        } else {
            uint256 _amount = _wethAmount.mul(10**18).div(_ttfPrice);
            _wethAmountDesired = _wethAmount;
            _ttfAmountDesired = _amount;
        }

        uint256 _wethAmountMin = _wethAmountDesired.sub(
            _wethAmountDesired.mul(5).div(100)
        );
        uint256 _ttfAmountMin = _ttfAmountDesired.sub(
            _ttfAmountDesired.mul(5).div(100)
        );

        address _token0 = ttfUniV2.token0();
        if (_token0 == wethAddress) {
            router02.addLiquidity(
                wethAddress,
                ttf,
                _wethAmountDesired,
                _ttfAmountDesired,
                _wethAmountMin,
                _ttfAmountMin,
                address(this),
                block.timestamp + DEADLINE
            );
        } else {
            router02.addLiquidity(
                ttf,
                wethAddress,
                _ttfAmountDesired,
                _wethAmountDesired,
                _ttfAmountMin,
                _wethAmountMin,
                address(this),
                block.timestamp + DEADLINE
            );
        }

        uint256 _wethQuantity = weth.balanceOf(address(this));
        uint256 _ttfQuantity = _ttf.balanceOf(address(this));
        if (_wethQuantity != 0) {
            weth.transfer(protocolVaultAddress, _wethQuantity);
        }
        if (_ttfQuantity != 0) {
            _ttf.transfer(ttfPoolAdress, _ttfQuantity);
        }

        return true;
    }


    /* Notice: It is withdrawn from the uniswapv2 pool at the entered percentage.
     *         Ttf is transferred to ttf pool.
     *         The weth protocol is transferred to the vault.   
     */
    function removeLiquidity(uint256 _percent)
        external
        override
        returns (bool)
    {
        require(msg.sender == protocolGradual, "Only gradualTaum");
        ERC20 _ttf = ERC20(ttf); 
        uint256 _totalSupply = ttfUniV2.totalSupply();
        
        uint256 _liquidity = ttfUniV2.balanceOf(address(this)).mul(_percent).div(100);
        uint256 _percentLiquidity = _liquidity.mul(10**18).div(_totalSupply);
        uint256 _reserveWeth;
        uint256 _reserveTtf;
        
        address _token0 = ttfUniV2.token0();
        if (_token0 == wethAddress) {
            (_reserveWeth,_reserveTtf,) = ttfUniV2.getReserves();
        }else{
            (_reserveTtf,_reserveWeth,) = ttfUniV2.getReserves();
        }
        
        uint256 _wethAmountMin = (_percentLiquidity.mul(_reserveWeth).div(10**18)).sub(
            (_percentLiquidity.mul(_reserveWeth).mul(5).div(10**19))
        );
        uint256 _ttfAmountMin = (_percentLiquidity.mul(_reserveTtf).div(10**18)).sub(
            (_percentLiquidity.mul(_reserveTtf).mul(5).div(10**19))
        );
        
        if (_token0 == wethAddress) {
            router02.removeLiquidity(wethAddress, ttf, _liquidity, _wethAmountMin, _ttfAmountMin, address(this), block.timestamp + DEADLINE);
        }else{
            router02.removeLiquidity(ttf, wethAddress, _liquidity, _ttfAmountMin, _wethAmountMin, address(this), block.timestamp + DEADLINE);
        }

        weth.transfer(protocolVaultAddress, weth.balanceOf(address(this)));
        _ttf.transfer(ttfPoolAdress, _ttf.balanceOf(address(this)));
        return (true);
    }
}
