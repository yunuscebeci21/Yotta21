// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {IUniswapPool} from "./interfaces/IUniswapPool.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IPrice} from "./interfaces/IPrice.sol";

contract PriceV1 is IPrice {
    using SafeMath for uint256;
    address public owner;
    address public manager;
    address public ottaUniPool;
    address public ttfUniPool;
    address public linkTokenUniPool;
    address public taum;
    address public ttf;
    address public uniswapV2Adapter;
    address public ethPoolAddress;
    address public ethVaultAddress;
    address public wethAddress;
    address public indexPoolAddress;
    address[] public components;
    bool public isVaultSetted = false;
    bool public isEthPoolSetted = false;

    mapping(address => address) private componentsUniPools;

    IWeth public weth;

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    constructor(
        address _manager,
        address _weth,
        address _linkTokenUniPool,
        address _ttfUniPool,
        address _ottaUniPool,
        address _taum,
        address _ttf,
        address[] memory _components
    ) {
        owner = msg.sender;
        require(_weth != address(0), "zero address");
        weth = IWeth(_weth);
        wethAddress = _weth;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_linkTokenUniPool != address(0), "zero address");
        linkTokenUniPool = _linkTokenUniPool;
        require(_ttfUniPool != address(0), "zero address");
        ttfUniPool = _ttfUniPool;
        require(_ottaUniPool != address(0), "zero address");
        ottaUniPool = _ottaUniPool;
        require(_taum != address(0), "zero address");
        taum = _taum;
        require(_ttf != address(0), "zero address");
        ttf = _ttf;
        require(_components.length > 0, "zero components");
        components = _components;
    }

    function setManager(address _manager) public onlyOwner returns (address) {
        require(_manager != address(0), "zero address");
        manager = _manager;
        owner = manager;
        return manager;
    }

    function setEthVault(address _ethVaultAddress) public onlyOwner {
        require(!isVaultSetted, "Already Setted");
        require(_ethVaultAddress != address(0), "zero address");
        ethVaultAddress = _ethVaultAddress;
        isVaultSetted = true;
    }

    function setEthPool(address _ethPoolAddress) public onlyOwner {
        require(!isEthPoolSetted, "Already Setted");
        require(_ethPoolAddress != address(0), "zero address");
        ethPoolAddress = _ethPoolAddress;
        isEthPoolSetted = true;
    }

    function setIndexPool(address _indexPoolAddress) public onlyOwner {
        require(_indexPoolAddress != address(0), "zero address");
        indexPoolAddress = _indexPoolAddress;
    }

    function setUniswapV2Adapter(address _uniswapV2Adapter) public onlyOwner {
        require(_uniswapV2Adapter != address(0), "zero address");
        uniswapV2Adapter = _uniswapV2Adapter;
    }

    function setUniPools(
        address[] calldata _components,
        address[] calldata _uniPools
    ) public onlyOwner {
        for (uint256 i = 0; i < _uniPools.length; i++) {
            componentsUniPools[_components[i]] = _uniPools[i];
        }
    }

    function getComponentPrice(address _componentAddress)
        external
        view
        override
        returns (uint256 _componentPrice)
    {
        address _componentPool = componentsUniPools[_componentAddress];
        IUniswapPool _component = IUniswapPool(_componentPool);
        address _token = _component.token0();
        if (_token == wethAddress) {
            (uint256 _reserveWeth, uint256 _reserveComponent, ) = _component
                .getReserves();
            _componentPrice = _reserveWeth.mul(10**18).div(_reserveComponent);
        } else {
            (uint256 _reserveComponent, uint256 _reserveWeth, ) = _component
                .getReserves();
            _componentPrice = _reserveWeth.mul(10**18).div(_reserveComponent);
        }
    }

    function getOttaPrice()
        external
        view
        override
        returns (uint256 _ottaPrice)
    {
        IUniswapPool _otta = IUniswapPool(ottaUniPool);
        address _token = _otta.token0();
        if (_token == wethAddress) {
            (uint256 _reserveWeth, uint256 _reserveOtta, ) = _otta
                .getReserves();
            _ottaPrice = _reserveWeth.mul(10**18).div(_reserveOtta);
        } else {
            (uint256 _reserveOtta, uint256 _reserveWeth, ) = _otta
                .getReserves();
            _ottaPrice = _reserveWeth.mul(10**18).div(_reserveOtta);
        }
    }

    function getTtfPrice() external view override returns (uint256 _ttfPrice) {
        IUniswapPool _ttf = IUniswapPool(ttfUniPool);
        address _token = _ttf.token0();
        if (_token == wethAddress) {
            (uint256 _reserveWeth, uint256 _reserveTtf, ) = _ttf.getReserves();
            _ttfPrice = _reserveWeth.mul(10**18).div(_reserveTtf);
        } else {
            (uint256 _reserveTtf, uint256 _reserveWeth, ) = _ttf.getReserves();
            _ttfPrice = _reserveWeth.mul(10**18).div(_reserveTtf);
        }
    }

    function getLinkPrice()
        external
        view
        override
        returns (uint256 _linkPrice)
    {
        IUniswapPool _linkToken = IUniswapPool(linkTokenUniPool);
        address _token = _linkToken.token0();
        if (_token == wethAddress) {
            (uint256 _reserveWeth, uint256 _reserveLink, ) = _linkToken
                .getReserves();
            _linkPrice = _reserveWeth.mul(10**18).div(_reserveLink);
        } else {
            (uint256 _reserveLink, uint256 _reserveWeth, ) = _linkToken
                .getReserves();
            _linkPrice = _reserveWeth.mul(10**18).div(_reserveLink);
        }
    }

   function getTaumPrice()
        external
        view
        override
        returns (uint256 _totalAmount, uint256 _protocolPercent, uint256 _taumPrice)
    {
        uint256 _poolAndVaultBalance = (weth.balanceOf(ethPoolAddress)).add(weth.balanceOf(ethVaultAddress));
        if(_poolAndVaultBalance == 0){
            _poolAndVaultBalance = _poolAndVaultBalance.mul(10**18);
        }
        ERC20 _ttf = ERC20(ttf);
        uint256 _ttfAmount = _ttf.balanceOf(indexPoolAddress).mul(this.getTtfPrice()).div(10**18);
        if(_ttfAmount == 0){
            _ttfAmount = _ttfAmount.mul(10**18);
        }
        IUniswapPool _ttfPool = IUniswapPool(ttfUniPool);
        uint256 _percent = _ttfPool.balanceOf(uniswapV2Adapter).mul(10**20).div(
            _ttfPool.totalSupply()
        );
        uint256 _reserveWeth;
        if(_ttfPool.token0() == wethAddress){
            (_reserveWeth,,) = _ttfPool.getReserves();
        }
        else{
            (, _reserveWeth,) = _ttfPool.getReserves();
        }
        uint256 _reserveAmountInUniswap = (_reserveWeth.mul(2)).mul(_percent).div(10**20);
        ERC20 _taum = ERC20(taum);
        _totalAmount = _poolAndVaultBalance.add(_reserveAmountInUniswap).add(_ttfAmount);
        _protocolPercent = _totalAmount.mul(10**18).div(weth.balanceOf(ethVaultAddress));
        _taumPrice = _totalAmount.mul(10**18).div(_taum.totalSupply());
    }
}
