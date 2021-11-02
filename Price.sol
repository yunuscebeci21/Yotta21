// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapPool} from "./interfaces/IUniswapPool.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IWeth} from "./interfaces/IWeth.sol";
import {IPrice} from "./interfaces/IPrice.sol";
import {IKeepRegistry} from "./chainlink/IKeepRegistry.sol";

contract Price is IPrice{

    using SafeMath for uint256;

    /* ================ Events ================== */
    
    event ManagerSetted(address _manager);
    event KeeperIDsSetted(uint256 _taumFeeKeeperId, uint256 _ottaLockKeeperId, uint256 _gradualKeeperId, uint256 _ethPoolKeeperId, uint256 _ttfPoolKeeperId, uint256 _selfKeeperId);
    event UniPoolsSetted(address[] _components, address[] _uniPools);
    event ProtocolVaultSetted(address _protocolVaultAddress);
    event EthPoolSetted(address _ethPoolAddress);
    event TTFPoolSetted(address _ttfPoolAddress);
    event UniswapV2AdapterSetted(address _uniswapV2Adapter);
    event KeeperRegistry(address _keeperRegistryAddress);

    /* ================ State Variables ================== */
   
    // address of contract creator
    address public owner;
    // address of manager
    address public manager;
    // address of otta univ2
    address public ottaUniPool;
    // address of ttf univ2
    address public ttfUniPool;
    //address of link univ2
    address public linkTokenUniPool;
    // address of taum
    address public taum;
    // address of ttf
    address public ttf;
    // address of uniswapV2 adapter
    address public uniswapV2Adapter;
    //address of ttfpool contract
    address public ttfPoolAddress;
    //address of ethpool contract 
    address public ethPoolAddress;
    // address of protocolvault contract
    address public protocolVaultAddress;
    // address of weth
    address public wethAddress;
    // addresses of component array
    address[] public components;
    // chainlink keeper id of taum token contract 
    uint256 public taumFeeKeeperId;
    // chainlink keeper id of otta token contract
    uint256 public ottaLockKeeperId;
    // chainlink keeper id of gradualTaum  contract
    uint256 public gradualKeeperId;
    // chainlink keeper id of ethereum pool contract
    uint256 public ethPoolKeeperId;
    // chainlink keeper id of ttf pool contract
    uint256 public ttfPoolKeeperId;
    // chainlink keeper id of this contract
    uint256 public selfKeeperId;
    // set status of this contract
    bool public isUniPoolsSetted;
    bool public isProtocolVaultSetted;
    bool public isTTFPoolSetted;
    bool public isEthPoolSetted;
    bool public isUniswapV2AdapterSetted;
    bool public isKeeperIDsSetted;
    // map of components univ2
    mapping(address => address) private componentsUniPools;
    // importing weth methods
    IWeth public weth;
    // importing keeper registry methods
    IKeepRegistry private keeper;

    /* ================ Modifier ================== */

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /* ================ Constructor ================== */
    constructor(
        address _manager,
        address _weth,
        address _linkTokenUniPool,
        address _ttfUniPool,
        address _ottaUniPool,
        address _taum,
        address _ttf,
        address _keeperRegistryAddress,
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
        require(_keeperRegistryAddress != address(0), "zero address");
        keeper = IKeepRegistry(_keeperRegistryAddress);
    }

    /* ================ Functions ================== */
    /* ================ Public Functions ================== */

    /*
     * Notice: Setting manager address
     * Params:
     * '_manager' The manager address
     */
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }

    /*
     * Notice: Setting uni pool addresses
     * Params:
     * '_components' The array of component adddresses 
     * '_uniPools' The array of component uni pools
     */
    function setUniPools(
        address[] calldata _components,
        address[] calldata _uniPools
    ) public onlyOwner returns(address[] calldata, address[] calldata){
        require(!isUniPoolsSetted, "Already setted");
        require(_components.length == _uniPools.length, "not equals");
        isUniPoolsSetted = true;
        for (uint256 i = 0; i < _uniPools.length; i++) {
            componentsUniPools[_components[i]] = _uniPools[i];
        }
        emit UniPoolsSetted(_components, _uniPools);
        return (_components, _uniPools);
    }

    /*
     * Notice: Setting protocol vault addresses
     * Params:
     * '_protocolVaultAddress' The protocol vault address
     */
    function setProtocolVault(address _protocolVaultAddress) public onlyOwner returns(address){
        require(!isProtocolVaultSetted, "Already setted");
        require(_protocolVaultAddress != address(0), "zero address");
        isProtocolVaultSetted = true;
        protocolVaultAddress = _protocolVaultAddress;
        emit ProtocolVaultSetted(protocolVaultAddress);
        return protocolVaultAddress;
    }

    /*
     * Notice: Setting ttf pool addresses
     * Params:
     * '_ttfPoolAddress' The ttf pool contract address
     */
    function setTTFPool(address _ttfPoolAddress) public onlyOwner returns(address){
        require(!isTTFPoolSetted, "Already setted");
        require(_ttfPoolAddress != address(0), "zero address");
        isTTFPoolSetted = true;
        ttfPoolAddress = _ttfPoolAddress;
        emit TTFPoolSetted(ttfPoolAddress);
        return ttfPoolAddress;
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
     * Notice: Setting uniswapV2Adapter addresses
     * Params:
     * '_uniswapV2Adapter' The uniswapV2Adapter contract address
     */
    function setUniswapV2Adapter(address _uniswapV2Adapter) public onlyOwner returns(address){
        require(!isUniswapV2AdapterSetted, "Already setted");
        require(_uniswapV2Adapter != address(0), "zero address");
        isUniswapV2AdapterSetted = true;
        uniswapV2Adapter = _uniswapV2Adapter;
        emit UniswapV2AdapterSetted(uniswapV2Adapter);
        return uniswapV2Adapter;
    }

    /*
     * Notice: Setting keeperRegistryAddress addresses
     * Params:
     * '_keeperRegistryAddress' The keeperRegistryAddress contract address
     */
    function setKeeperRegitry(address _keeperRegistryAddress) public onlyOwner returns(address){
        require(_keeperRegistryAddress != address(0), "zero address");
        keeper = IKeepRegistry(_keeperRegistryAddress);
        emit KeeperRegistry(_keeperRegistryAddress);
        return _keeperRegistryAddress;
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
        require(!isKeeperIDsSetted, "Already setted");
        isKeeperIDsSetted = true;
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
     * Notice: component prices calculate from uniswap v2 
     */
    function getComponentPrice(address _componentAddress)
        external
        view
        override
        returns (uint256 _componentPrice)
    {
        address _componentPool = componentsUniPools[_componentAddress];
        IUniswapPool _component = IUniswapPool(_componentPool);
        address _token = _component.token0();
        if(_token == wethAddress){
        (uint256 _reserveWeth,uint256 _reserveComponent, ) = _component
            .getReserves();
        _componentPrice = _reserveWeth.mul(10**18).div(_reserveComponent);
        }
        else{
 
        (uint256 _reserveComponent, uint256 _reserveWeth, ) = _component
            .getReserves();
        _componentPrice = _reserveWeth.mul(10**18).div(_reserveComponent);
        }
    }

    /*
     * Notice: otta price calculate from uniswap v2 
     */
    function getOttaPrice() external view override returns (uint256 _ottaPrice) {
        IUniswapPool _otta = IUniswapPool(ottaUniPool);
        address _token = _otta.token0();
        if(_token == wethAddress){
        (uint256 _reserveWeth, uint256 _reserveOtta, ) = _otta.getReserves();
        _ottaPrice = _reserveWeth.mul(10**18).div(_reserveOtta);
        }
        else{
        (uint256 _reserveOtta,uint256 _reserveWeth, ) = _otta.getReserves();
        _ottaPrice = _reserveWeth.mul(10**18).div(_reserveOtta);
        }
    
    }
 
    /*
     * Notice: ttf price calculate from uniswap v2 
     */
    function getTtfPrice() external view override returns (uint256 _ttfPrice) {
        IUniswapPool _ttf = IUniswapPool(ttfUniPool);
        address _token = _ttf.token0();
        if(_token == wethAddress){

        ( uint256 _reserveWeth,uint256 _reserveTtf, ) = _ttf.getReserves();
            _ttfPrice = _reserveWeth.mul(10**18).div(_reserveTtf);
        }
        else{
        (uint256 _reserveTtf, uint256 _reserveWeth, ) = _ttf.getReserves();
        _ttfPrice = _reserveWeth.mul(10**18).div(_reserveTtf);           
        }
    }

    /*
     * Notice: link price calculate from uniswap v2 
     */
    function getLinkPrice() external view override returns(uint256 _linkPrice){
        IUniswapPool _linkToken = IUniswapPool(linkTokenUniPool);
        address _token = _linkToken.token0();
        if(_token == wethAddress){

            (uint256 _reserveWeth,uint256 _reserveLink,) = _linkToken.getReserves();
            _linkPrice = _reserveWeth.mul(10**18).div(_reserveLink);
        }
        else{
        (uint256 _reserveLink, uint256 _reserveWeth,) = _linkToken.getReserves();
        _linkPrice = _reserveWeth.mul(10**18).div(_reserveLink);
        }
    }

    /*
     * Notice: total link balance calculate from keeper 
     */
    function getKeeperBalance() internal view returns(uint96){
        uint96 _currentBalanceTaum;
        uint96 _currentBalanceOtta;
        uint96 _currentBalancePool;
        uint96 _currentBalanceTtfPool;
        uint96 _currentBalanceGradual;
        uint96 _currentBalanceSelf;
        
        (, , , _currentBalanceTaum, , , ) = keeper.getUpkeep(taumFeeKeeperId);
        (, , , _currentBalanceOtta, , , ) = keeper.getUpkeep(ottaLockKeeperId);
        (, , , _currentBalancePool, , , ) = keeper.getUpkeep(ethPoolKeeperId);
        (, , , _currentBalanceGradual, , , ) = keeper.getUpkeep(gradualKeeperId);
        (, , , _currentBalanceTtfPool, , , ) = keeper.getUpkeep(ttfPoolKeeperId);
        (, , , _currentBalanceSelf, , , ) = keeper.getUpkeep(selfKeeperId);
        return _currentBalanceTaum + _currentBalanceOtta + _currentBalancePool + _currentBalanceGradual + _currentBalanceTtfPool + _currentBalanceSelf;
    }

    /*
     * Notice: taum price calculate
     */
    function getTaumPrice(uint256 _ethAmount)
        external
        view
        override
        returns (uint256 _totalAmount, uint256 _protocolPercent, uint256 _taumPrice)
    {
        uint256 _poolAndVaultBalance = (weth.balanceOf(ethPoolAddress)).add(weth.balanceOf(protocolVaultAddress)).sub(_ethAmount);
        ERC20 _ttf = ERC20(ttf);
        uint256 _ttfAmount = _ttf.balanceOf(ttfPoolAddress).mul(this.getTtfPrice()).div(10**18);
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
        
        uint256 _totalLinkBalance = uint256(getKeeperBalance()).mul(this.getLinkPrice()).div(10**18);
        
        ERC20 _taum = ERC20(taum);
        _totalAmount = _poolAndVaultBalance.add(_reserveAmountInUniswap).add(_ttfAmount).add(_totalLinkBalance);
        _protocolPercent = weth.balanceOf(protocolVaultAddress).mul(10**20).div(_totalAmount);
        _taumPrice = _totalAmount.mul(10**18).div(_taum.totalSupply());
    }
}