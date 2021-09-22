// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {IUniswapV2Router02} from "./uniswap/IUniswapV2Router02.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IIndexLiquidityPool} from "./interfaces/IIndexLiquidityPool.sol";
import {IUniswapPool} from "./interfaces/IUniswapPool.sol";
import {IUniswapV2Adapter} from "./interfaces/IUniswapV2Adapter.sol";

contract UniswapV2Adapter is IUniswapV2Adapter{
    using SafeMath for uint256;

    address public owner;
    address public manager;
    address public weth;
    address public ttf;
    address public router02Address;
    address public UniswapTtfPoolAddress;
    address public indexLiquidityPoolAdress;
    address public ethVault;
    address public gradualTaum;
    uint256 public constant DEADLINE = 5 hours;
    uint256 public constant MAX_INT = 2**256 - 1;
    bool public isIndexPoolSetted = false;
    bool public isEthVaultSetted = false;
    bool public isGradualSetted = false;
    IUniswapV2Router02 public router02;
    IIndexLiquidityPool public indexPool;
    IUniswapPool public ttfPoolUni;

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

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
        weth = _weth;
        require(_ttf != address(0), "zero address");
        ttf = _ttf;
        require(_uniswapTtfPool != address(0),"zero address");
        ttfPoolUni = IUniswapPool(_uniswapTtfPool);
    }

    function setManager(address _manager) public onlyOwner returns (address) {
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }

    function setIndexPool(address _indexLiquidityPoolAddress)
        public
        onlyOwner
        returns (address indexLiquidityPoolAddress)
    {
        require(!isIndexPoolSetted, "Already setted");
        require(_indexLiquidityPoolAddress != address(0), "zero address");
        indexLiquidityPoolAdress = _indexLiquidityPoolAddress;
        indexPool = IIndexLiquidityPool(indexLiquidityPoolAdress);
        isIndexPoolSetted = true;
        //emit IndexPoolSetted(indexLiquidityPoolAdress);
        return (indexLiquidityPoolAdress);
    }
         
    function setEthVault(address payable _ethVault)
        public
        onlyOwner
        returns (address ethVaultAddress)
    {
        require(!isEthVaultSetted, "Already setted");
        require(_ethVault != address(0), "zero address");
        ethVault = _ethVault;
        isEthVaultSetted = true;
        emit EthVaultSetted(ethVault);
        return (ethVault);
    }
    
    function setGradualTaum(address _gradualAddress)
        public
        onlyOwner
        returns (address gradualTaumAddress)
    {
        require(!isGradualSetted, "Already setted");
        require(_gradualAddress != address(0), "zero address");
        gradualTaum = _gradualAddress;
        isGradualSetted = true;
        emit GradualSetted(gradualTaum);
        return (gradualTaum);
    }

    function bringIndexesFromPool() external override returns (bool state) {
        indexPool.sendIndex();
        return true;
    }

    function approveTokens() external override {
        ERC20 _weth = ERC20(weth);
        bool success = _weth.approve(router02Address, MAX_INT);
        require(success, "weth approve error");
        ERC20 _ttf = ERC20(ttf);
        bool success2 = _ttf.approve(router02Address, MAX_INT);
        require(success2, "Index approve error");
    }

    function addLiquidity() external override returns(bool){ 
        ERC20 _ttf = ERC20(ttf);
        ERC20 _weth = ERC20(weth);
        uint256 _ttfAmountDesired = _ttf.balanceOf(address(this));
        uint256 _wethAmountDesired = _weth.balanceOf(address(this));
        uint256 _wethAmountMin = _wethAmountDesired.sub(
            _wethAmountDesired.div(1000)
        );
        uint256 _ttfAmountMin = _ttfAmountDesired.sub(
            _ttfAmountDesired.div(1000)
        );
        router02.addLiquidity(
            weth,
            ttf,
            _ttfAmountDesired,
            _wethAmountDesired,
            _wethAmountMin,
            _ttfAmountMin,
            address(this),
            block.timestamp + DEADLINE
        );
        return(true);
    }

    function removeLiquidity(uint256 _percent) external override returns(bool){
        require(msg.sender == gradualTaum,"Only gradualTaum");
        ERC20 _weth = ERC20(weth);
        ERC20 _ttf = ERC20(ttf); 
        uint256 _totalSupply = ttfPoolUni.totalSupply();
        uint256 _selfBalance = ttfPoolUni.balanceOf(address(this));
        uint256 _totalLiquidity = _selfBalance.mul(10**20).div(_totalSupply);
        uint256 _liquidity = _totalLiquidity.mul(_percent).div(100);
        router02.removeLiquidity(weth, ttf, _liquidity, 0, 0, address(this), block.timestamp+DEADLINE);
        _weth.transfer(ethVault, _weth.balanceOf(address(this)));
        _ttf.transfer(indexLiquidityPoolAdress, _ttf.balanceOf(address(this))); 
        return(true);
    }
}