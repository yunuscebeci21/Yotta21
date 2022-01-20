// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV2Router02} from "./external/IUniswapV2Router02.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ITTFFPool} from "./interfaces/ITTFFPool.sol";
import {IUniswapV2Pool} from "./external/IUniswapV2Pool.sol";
import {IUniswapV2Adapter} from "./interfaces/IUniswapV2Adapter.sol";
import {IPrice} from "./interfaces/IPrice.sol";
import {IWeth} from "./external/IWeth.sol";

contract UniswapV2Adapter is IUniswapV2Adapter {
    using SafeMath for uint256;

    /*================== Events ===================*/
    /// @notice An event thats emitted when TTFFPool contract address setting
    event TTFFPoolSetted(address _ttffPoolAddress);
    /// @notice An event thats emitted when Price contract address setting
    event PriceSetted(address _priceAddress);
    /// @notice An event thats emitted when ProtocolVault contract address setting
    event ProtocolVaultSetted(address _protocolVaultAddress);
    /// @notice An event thats emitted when EthereumPool contract address setting
    event EthPoolSetted(address _ethPoolAddress);
    /// @notice An event thats emitted when ProtocolGradual contract address setting
    event ProtocolGradualSetted(address _protocolGradualAddress);

    /*================== State Variables ===================*/
    /// @notice Address of contract creator
    address public owner;
    /// @notice Address of weth address
    address public wethAddress;
    /// @notice address of ttff token
    address public ttff;
    /// @notice Address of Router02 contract address
    address public router02Address;
    /// @notice Address of ttff pool contract
    address public ttffPoolAdress;
    /// @notice Address of protocol vault contract
    address public protocolVaultAddress;
    /// @notice Address of ethereum pool contract
    address public ethPoolAddress;
    /// @notice Address of protocol gradual contract
    address public protocolGradual;
    /// @notice Transaction revert time
    uint256 public constant DEADLINE = 5 hours;
    /// @notice Maximum integer value
    uint256 public constant MAX_INT = 2**256 - 1;
    /// @notice Ttff's pool address after it was added to univ2
    address public ttffUniV2Address;
    /// @notice Set status of this contract
    bool public isTTFFPoolSetted;
    bool public isPriceSetted;
    bool public isProtocolVaultSetted;
    bool public isEthPoolSetted;
    bool public isProtocolGradualSetted;
    /// @notice Importing UniswapV2Router02 contract interface
    IUniswapV2Router02 public router02;
    /// @notice Importing TTFFPool contract interface
    ITTFFPool public ttffPool;
    /// @notice Importing UniswapPool interface
    IUniswapV2Pool public ttffUniV2;
    /// @notice Importing Price contract interface
    IPrice public price;
    /// @notice Importing Weth contract interface
    IWeth public weth;

    /* ================ Modifier ================== */
    /// @notice Throws if the sender is not owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /*=============== Constructor ========================*/
    constructor(
        address _router02,
        address _weth,
        address _ttff,
        address _uniswapTtfPool
    ) {
        owner = msg.sender;
        require(_router02 != address(0), "zero address");
        router02 = IUniswapV2Router02(_router02);
        router02Address = _router02;
        require(_weth != address(0), "zero address");
        wethAddress = _weth;
        weth = IWeth(wethAddress);
        require(_ttff != address(0), "zero address");
        ttff = _ttff;
        require(_uniswapTtfPool != address(0), "zero address");
        ttffUniV2 = IUniswapV2Pool(_uniswapTtfPool);
        ttffUniV2Address = _uniswapTtfPool;
    }

    /*================== Functions =====================*/
    /*================== External Functions =====================*/
    /// @notice Up to MAX_INT, router02 address is approved to weth, ttff, ttffUniV2
    function approveTokens() external onlyOwner {
        ERC20 _weth = ERC20(wethAddress);
        bool success = _weth.approve(router02Address, MAX_INT);
        require(success, "Weth approve error");
        ERC20 _ttff = ERC20(ttff);
        bool success2 = _ttff.approve(router02Address, MAX_INT);
        require(success2, "TTFF approve error");
        ERC20 _ttffPool = ERC20(ttffUniV2Address);
        bool success3 = _ttffPool.approve(router02Address, MAX_INT);
        require(success3, "TTFF UniV2 approve error");
    }

    /// @inheritdoc IUniswapV2Adapter
    function bringTTFFsFromPool() external override returns (bool) {
        require(msg.sender == ethPoolAddress, "Only Ethereum Pool");
        ttffPool.sendTTFF();
        return true;
    }

    /// @inheritdoc IUniswapV2Adapter
    function addLiquidity() external override returns (bool) {
        require(msg.sender == ethPoolAddress, "Only Ethereum Pool");
        ERC20 _ttff = ERC20(ttff);
        ERC20 _weth = ERC20(wethAddress);
        uint256 _ttffPrice = price.getTtffPrice();
        uint256 _ttffAmount = (_ttff.balanceOf(address(this)))
            .mul(_ttffPrice)
            .div(10**18);
        uint256 _wethAmount = (_weth.balanceOf(address(this)));
        uint256 _ttffAmountDesired;
        uint256 _wethAmountDesired;
        if (_wethAmount == _ttffAmount) {
            _wethAmountDesired = _wethAmount;
            _ttffAmountDesired = _ttff.balanceOf(address(this));
        } else if (_wethAmount > _ttffAmount) {
            _wethAmountDesired = _ttffAmount;
            _ttffAmountDesired = _ttff.balanceOf(address(this));
        } else {
            uint256 _amount = _wethAmount.mul(10**18).div(_ttffPrice);
            _wethAmountDesired = _wethAmount;
            _ttffAmountDesired = _amount;
        }
        uint256 _wethAmountMin = _wethAmountDesired.sub(
            _wethAmountDesired.mul(5).div(100)
        );
        uint256 _ttffAmountMin = _ttffAmountDesired.sub(
            _ttffAmountDesired.mul(5).div(100)
        );
        address _token0 = ttffUniV2.token0();
        if (_token0 == wethAddress) {
            router02.addLiquidity(
                wethAddress,
                ttff,
                _wethAmountDesired,
                _ttffAmountDesired,
                _wethAmountMin,
                _ttffAmountMin,
                address(this),
                block.timestamp + DEADLINE
            );
        } else {
            router02.addLiquidity(
                ttff,
                wethAddress,
                _ttffAmountDesired,
                _wethAmountDesired,
                _ttffAmountMin,
                _wethAmountMin,
                address(this),
                block.timestamp + DEADLINE
            );
        }
        uint256 _wethQuantity = weth.balanceOf(address(this));
        uint256 _ttffQuantity = _ttff.balanceOf(address(this));
        if (_wethQuantity != 0) {
            weth.transfer(protocolVaultAddress, _wethQuantity);
        }
        if (_ttffQuantity != 0) {
            _ttff.transfer(ttffPoolAdress, _ttffQuantity);
        }
        return true;
    }

    /// @inheritdoc IUniswapV2Adapter
    function removeLiquidity(uint256 _percent)
        external
        override
        returns (bool)
    {
        require(msg.sender == protocolGradual, "Only Protocol Gradual");
        ERC20 _ttff = ERC20(ttff);
        uint256 _totalSupply = ttffUniV2.totalSupply();
        uint256 _liquidity = ttffUniV2
            .balanceOf(address(this))
            .mul(_percent)
            .div(100);
        uint256 _percentLiquidity = _liquidity.mul(10**18).div(_totalSupply);
        uint256 _reserveWeth;
        uint256 _reserveTtf;
        address _token0 = ttffUniV2.token0();
        if (_token0 == wethAddress) {
            (_reserveWeth, _reserveTtf, ) = ttffUniV2.getReserves();
        } else {
            (_reserveTtf, _reserveWeth, ) = ttffUniV2.getReserves();
        }
        uint256 _wethAmountMin = (
            _percentLiquidity.mul(_reserveWeth).div(10**18)
        ).sub((_percentLiquidity.mul(_reserveWeth).mul(5).div(10**19)));
        uint256 _ttffAmountMin = (
            _percentLiquidity.mul(_reserveTtf).div(10**18)
        ).sub((_percentLiquidity.mul(_reserveTtf).mul(5).div(10**19)));
        if (_token0 == wethAddress) {
            router02.removeLiquidity(
                wethAddress,
                ttff,
                _liquidity,
                _wethAmountMin,
                _ttffAmountMin,
                address(this),
                block.timestamp + DEADLINE
            );
        } else {
            router02.removeLiquidity(
                ttff,
                wethAddress,
                _liquidity,
                _ttffAmountMin,
                _wethAmountMin,
                address(this),
                block.timestamp + DEADLINE
            );
        }
        weth.transfer(protocolVaultAddress, weth.balanceOf(address(this)));
        _ttff.transfer(ttffPoolAdress, _ttff.balanceOf(address(this)));
        return (true);
    }

    /*================== Public Functions =====================*/
    /// @notice Setting ttff pool address
    /// @param _ttffPoolAddress The ttff pool contract address.
    function setTTFFPool(address _ttffPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isTTFFPoolSetted, "Already setted");
        require(_ttffPoolAddress != address(0), "Zero address");
        isTTFFPoolSetted = true;
        ttffPoolAdress = _ttffPoolAddress;
        ttffPool = ITTFFPool(ttffPoolAdress);
        emit TTFFPoolSetted(ttffPoolAdress);
        return (ttffPoolAdress);
    }

    /// @notice Setting price contract address
    /// @param _priceAddress The price contract address.
    function setPrice(address _priceAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isPriceSetted, "Already setted");
        require(_priceAddress != address(0), "Zero address");
        isPriceSetted = true;
        price = IPrice(_priceAddress);
        emit PriceSetted(_priceAddress);
        return (_priceAddress);
    }

    /// @notice Setting protocol vault contract address
    /// @param _protocolVaultAddress The protocol vault contract address.
    function setProtocolVault(address _protocolVaultAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isProtocolVaultSetted, "Already setted");
        require(_protocolVaultAddress != address(0), "Zero address");
        isProtocolVaultSetted = true;
        protocolVaultAddress = _protocolVaultAddress;
        emit ProtocolVaultSetted(protocolVaultAddress);
        return (protocolVaultAddress);
    }

    /// @notice Setting ethereum pool address
    /// @param _ethPoolAddress The ethereum pool address.
    function setEthPool(address _ethPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isEthPoolSetted, "Already setted");
        require(_ethPoolAddress != address(0), "Zero address");
        isEthPoolSetted = true;
        ethPoolAddress = _ethPoolAddress;
        emit EthPoolSetted(ethPoolAddress);
        return (ethPoolAddress);
    }

    /// @notice Setting protocol gradual address
    /// @param _protocolGradualAddress The protocol gradual address.
    function setProtocolGradual(address _protocolGradualAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isProtocolGradualSetted, "Already setted");
        require(_protocolGradualAddress != address(0), "Zero address");
        isProtocolGradualSetted = true;
        protocolGradual = _protocolGradualAddress;
        emit ProtocolGradualSetted(protocolGradual);
        return (protocolGradual);
    }
}
