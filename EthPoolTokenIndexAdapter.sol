// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import {IBasicIssuanceModule} from "./tokenSet/IBasicIssuanceModule.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IEthPoolTokenIndexAdapter} from "./interfaces/IEthPoolTokenIndexAdapter.sol";
import {IBuyComponents} from "./interfaces/IBuyComponents.sol";
import {IEthereumPool} from "./interfaces/IEthereumPool.sol";
import {IIndexLiquidityPool} from "./interfaces/IIndexLiquidityPool.sol";

/// @title Uniswap Adapter
/// @author Yotta21
contract EthPoolTokenIndexAdapter is IEthPoolTokenIndexAdapter {
    /* ================= State Variables ================= */

    // Address of Wrapped Ether
    address private wethAddress;
    // Address of index liquidity pool
    address public indexPoolAddress;
    // Address of Ethereum pool
    address payable public ethPoolAddress;
    // Address of owner
    address public owner;
    // address of manager
    address public manager;
    // Address of issuance module
    address public issuanceModuleAddress;
    // Address of component buyer
    address public buyerAddress;
     // maximum size of uint256
    uint256 public constant MAX_INT = 2**256 - 1;
    // set states of protocol contracts
    bool public isIndexPoolSetted = false;
    bool public isEthPoolSetted = false;
    // Importing Ethereum pool methods
    IEthereumPool private ethPool;
    // Importing index liquidity pool methods
    IIndexLiquidityPool private indexPool;
    // Importing Component buyer methods
    IBuyComponents private buyer;
    // Importing issuance module methods
    IBasicIssuanceModule private issuanceModule;

    /* ================= Modifiers ================= */

    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }


    /* ================= Constructor ================= */
    constructor(address _manager, address _wethAddress, address _issuanceModuleAddress) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_wethAddress != address(0), "zero address");
        wethAddress = _wethAddress;
        require(_issuanceModuleAddress != address(0), "zero address");
        issuanceModuleAddress = _issuanceModuleAddress;
        issuanceModule = IBasicIssuanceModule(issuanceModuleAddress);
    }

    /* =================  Functions ================= */
    /* ================= Public Functions ================= */
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }
    /*
     * Notice: Setting buyer address and importing methods
     * Param:
     * '_buyerAddress' address of buyer
     */
    function setBuyer(address _buyerAddress)
        public
        onlyOwner
        returns (address)
    {
        require(_buyerAddress != address(0), "zero address");
        buyerAddress = _buyerAddress;
        buyer = IBuyComponents(buyerAddress);
        emit BuyerAddressChanged(buyerAddress);
        return buyerAddress;
    }

    /*
     * Notice: Setting index liquidity pool address and importing methods
     * Param:
     * '_indexPoolAddress' address of index liquidity pool
     */
    function setIndexPool(address _indexPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isIndexPoolSetted, "Already setted");
        require(_indexPoolAddress != address(0), "zero address");
        indexPoolAddress = _indexPoolAddress;
        indexPool = IIndexLiquidityPool(indexPoolAddress);
        emit IndexPoolSetted(indexPoolAddress);
        isIndexPoolSetted = true;
        return (indexPoolAddress);
    }

    /*
     * Notice: Setting ethereum pool address and importing methods
     * Param:
     * '_ethPoolAddress' address of ethereum pool
     */
    function setEthPool(address payable _ethPoolAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isEthPoolSetted, "Already Setted");
        require(_ethPoolAddress != address(0), "zero address");
        ethPoolAddress = _ethPoolAddress;
        ethPool = IEthereumPool(ethPoolAddress);
        emit EthPoolSetted(ethPoolAddress);
        isEthPoolSetted = true;
        return (ethPoolAddress);
    }

    function approveComponents() public {
        address _index = indexPool.getIndex();
            ISetToken _ttf = ISetToken(_index);
            address[] memory _components = _ttf.getComponents();
            for (uint256 j = 0; j < _components.length; j++) {
                ERC20 _component = ERC20(_components[j]);
                _component.approve(issuanceModuleAddress, MAX_INT);
            }
    }

    /* ================= External Functions ================= */

    /*
     * Notice: getter method of required components for create index
     * Params:
     * '_index' address of index. Must be inherit from ISetToken
     * '_quantity' quantity of index to issue
     * Returns: array of component addresses and array of required quantity
     *
     */
    function getRequiredComponents(ISetToken _index, uint256 _quantity)
        external
        override
        returns (address[] memory, uint256[] memory)
    {
        (
            address[] memory _components,
            uint256[] memory _values
        ) = issuanceModule.getRequiredComponentUnitsForIssue(_index, _quantity);

        return (_components, _values);
    }

    /*
     * Notice: It buys components
     * Param:
     * '_component' address of component to buy
     * '_value' Quantity of component to buy
     * '_wethQuantity' quantity of wrapped ether to swap with component
     */
    function buyIndexComponents(
        address _component,
        uint256 _value,
        uint256 _wethQuantity
    ) external payable override returns (bool) {
        buyer.buyComponents(_component, _value, _wethQuantity);
        return true;
    }

    /*
     * Notice: Minting index to index liquidity pool
     */
    function issueIndex() external payable override returns (bool) {
        require(msg.sender == ethPoolAddress, "Only Ether Pool");
        address _index = indexPool.getIndex();
        ISetToken _ttf = ISetToken(_index);
        uint256 _quantity = ethPool._issueQuantity();
        issuanceModule.issue(_ttf, _quantity, indexPoolAddress);
        return (true);
    }

 
}
