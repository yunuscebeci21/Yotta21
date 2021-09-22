// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IReward} from "./interfaces/IReward.sol";
import {IPrice} from "./interfaces/IPrice.sol";
import {IOttaToken} from "./interfaces/IOttaToken.sol";

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import {IStreamingFeeModule} from "./tokenSet/IStreamingFeeModule.sol";
import {IIndexLiquidityPool} from "./interfaces/IIndexLiquidityPool.sol";

/// @title Otta Token
/// @author Yotta21
contract OttaToken is Context, IERC20, IERC20Metadata, IOttaToken {
    using SafeMath for uint256;

    /*================== Variables ===================*/
    // token name for otta token
    string private _name;
    // token symbol for otta token
    string private _symbol;
    // token decimals for otta token
    uint8 private _decimals;
    // day counter for reward lock time and unlock time
    uint16 public rewardDayCounter;
    // total supply of tokens
    uint256 private _totalSupply;
    // total locked supply, set zero first
    uint256 private lockedSupply;
    // total unlocked supply, set zero first
    uint256 public unlockedSupply;
    // Chainlink keeper call time
    uint256 private interval;
    // Block Timestamp
    uint256 private lastTimeStamp;
    // daily cumulative protocol fee
    uint256 public protocolFeeBalance;
    // max mint token
    uint256 public constant TOTAL_SUPPLY = 44 * (10**24);
    // mint amount for ico
    uint256 public constant ICO_SUPPLY = 19232 * (10**20);
    // address of owner 
    address public ownerAddress;
    // address of manager
    address public manager;
    // address of reward contract 
    address public rewardAddress;
    IIndexLiquidityPool private indexPool;
    // address of multisign wallet contract 
    address private walletContractAddress;   
    //price set status
    bool public isPriceSetted = false;
    // Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) private _allowances;
    // Official record of token balances for each account
    mapping(address => uint256) private _balances;
     // importing reward contract interface as reward
    IReward private reward;
    // importing price contract interface as price
    IPrice private price;
    // Accrue streaming fee from tokenSet
    IStreamingFeeModule private streamingFee;

    /*================== Modifiers =====================*/
    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == ownerAddress || msg.sender == manager, "Only Owner");
        _;
    }

    /*=============== Constructor ========================*/
    constructor(
        address _manager,
        string memory name_,
        string memory symbol_,
        uint256 _interval,
        address _rewardAddress,
        address _streamingFeeModule
    ) {
        ownerAddress = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        interval = _interval;
        require(_rewardAddress != address(0), "zero address");
        rewardAddress = _rewardAddress;
        reward = IReward(rewardAddress);
        require(_streamingFeeModule != address(0),"zero address");
        streamingFee = IStreamingFeeModule(_streamingFeeModule);
        _mint(address(this), TOTAL_SUPPLY);
        _transfer(address(this), ownerAddress, ICO_SUPPLY);
        uint256 lockedAmount = _totalSupply.sub(ICO_SUPPLY);
        lockedSupply = lockedAmount;
    }

    /*================== Public Functions =====================*/
     function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }

    /* Notice: Setting wallet contract address
     * Params:
     * '_walletContractAddress' The new wallet contract address.
     * Return:
     * 'walletContractAddress' The current wallet contract address.
     * Requirements:
     * '_walletContractAddress' cannot be the zero address.
     */
    function setWalletContract(address _walletContractAddress)
        public
        onlyOwner
        returns (address newWalletContractAddress)
    {
        require(_walletContractAddress != address(0), "zero address");
        walletContractAddress = _walletContractAddress;
        emit WalletContractSetted(walletContractAddress);
        return (walletContractAddress);
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
        price = IPrice(_priceAddress);
        return _priceAddress;
    }
    /* Notice: Setting Index Liquidity Pool contract address methods
     * Params:
     * '_indexPoolAddress' The Index Liquidity Pool contract address.
     * Requirements:
     * '_indexPoolAddress' cannot be the zero address.
     */
    function setIndexPool(address _indexPoolAddress) public onlyOwner{
        require(_indexPoolAddress != address(0),"zero address");
        indexPool = IIndexLiquidityPool(_indexPoolAddress);
    }

    function setInterval(uint256 _interval) public onlyOwner{
        require(_interval != 0,"zero interval");
        interval = _interval;
    }
    /*
     *  Return: The name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /*
     *  Return: The symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /*
     *  Return: The decimals of the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /*
     *  Return: The total supply of the token.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /*
     *  Return: The balance of the account.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /*
     *  Notice: "sperder" value by "owner" for token.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /*
     *  Notice: Sets the "spender" value with "sender" tokens
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /*
     *  Notice: automatically increases
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /*
     *  Notice: automatically decrease
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(
            _msgSender(),
            spender,
            currentAllowance.sub(subtractedValue)
        );
        return true;
    }

    /*
     *  Notice: Moves `amount` tokens from the caller's account to `recipient`
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*
     *  Notice: Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
     * `amount` is then deducted from the caller's allowance.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance.sub(amount));
        return true;
    }

    /*
     * Notice: The function to be triggered when the otta token will take
     * The amount of ethereum sent is calculated based on the otta price.
     * Otta token is transferred to the caller and the protocol.
     */
   function buyTokens() public payable {
        uint256 _ethAmount = msg.value;
        require(msg.sender != address(0), "zero address");
        address _userAddress = msg.sender;
        require(_ethAmount != 0, "insufficient eth amount");
        uint256 _ottaPrice = price.getOttaPrice();
        uint256 _tokens = (_ethAmount.mul(10**18)).div(_ottaPrice);
        uint256 _userAllowance = 0 * 10 ** 18;
        if(_tokens >= (1000 * 10 ** 18)){ 
         _userAllowance = _ethAmount.mul(2).div(100);
          payable(_userAddress).transfer(_userAllowance);
        }
        uint256 _protocolFee = _tokens.mul(25).div(100);
        payable(rewardAddress).transfer(_ethAmount.sub(_userAllowance));
        _transferFromContract(msg.sender, _tokens);
        _transferProtocolFee(_protocolFee);
        emit OttaTokenPurchased(msg.sender, _tokens);
    }

    /*================== External Functions =====================*/
    /*
     * Notice: Checking the upkeepNeeded condition
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    /*
     * Notice: Chainlink Keeper method calls unlocked method
     */
    function performUpkeep(bytes calldata performData) external {
        lastTimeStamp = block.timestamp;
        unlocked();
        collectStreamingFee();
        performData;
    }

/*================== Internal Functions =====================*/
    /* Notice: Triggers every 24 hours
     * Unlocks 3600 tokens each time triggered
     * Unlocked tokens are split into two: 'unlockedSupply' and 'protocolFeeBalance'
     * Sale is made from 'unlockedSupply'
     * Mint for protocol from 'protocolFeeBalance'
     */
    function unlocked() internal {
        if (lockedSupply == 0) {
            rewardDayCounter += 1;
            if (rewardDayCounter == 24) {
                reward.setEpoch(true);
            }
            if (rewardDayCounter == 48) {
                reward.setEpoch(false);
                rewardDayCounter = 0;
            }
        } else {
            lockedSupply = lockedSupply.sub(7200 * 10 ** 18);
            unlockedSupply = unlockedSupply.add(5760 * 10 ** 18);
            protocolFeeBalance = protocolFeeBalance.add(1440 * 10 ** 18);
            rewardDayCounter += 1;
            if (rewardDayCounter == 24) {
                reward.setEpoch(true);
            }
            if (rewardDayCounter == 48) {
                reward.setEpoch(false);
                rewardDayCounter = 0;
            }
        }
    }
    /*
     * Notice: Collecting TTF streaming fee
     */
    function collectStreamingFee() internal{
        ISetToken _ttf = ISetToken(indexPool.getIndex());
        streamingFee.accrueFee(_ttf);
    }
    /*
     * Notice: Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * Requirements:
     * `owner` cannot be the zero address.
     * `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /*
     * Notice: Moves `amount` of tokens from `sender` to `recipient`.
     * Requirements:
     * `sender` cannot be the zero address.
     * `recipient` cannot be the zero address.
     * `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    /*
     * Notice: Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * Requirements:
     * `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /*
     * Notice: Destroys `amount` tokens from `account`, reducing the total supply.
     * Requirements:
     * `account` cannot be the zero address.
     * `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(
            msg.sender == address(this),
            "Address without permission to run the function"
        );

        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    /*
     * Hook that is called before any transfer of tokens. This includes minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /*
     * Hook that is called after any transfer of tokens. This includes minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

     /*
     * Notice: Transfer function written for the protocol to transfer 
     * from "unlockedSupply" after selling otta tokens
     * 'sender' this contract
     * Requirements:
     * 'recipient' cannot be the zero address.
     * `sender` must have a balance of at least `amount`.
     */
    function _transferFromContract(address recipient, uint256 amount)
        internal
        virtual
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(address(this), recipient, amount);
        uint256 senderBalance = unlockedSupply;
        require(senderBalance >= amount, "Insufficient Unlocked Supply!");
        unlockedSupply = unlockedSupply.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(address(this), recipient, amount);
        _afterTokenTransfer(address(this), recipient, amount);
    }

    /*
     * Notice: Transfer function written for the protocol to transfer 
     * from "protocolFeeBalance" after selling otta tokens
     * 'sender' this contract
     * 'recipient' wallet contract
     * Requirements:
     * 'recipient' cannot be the zero address.
     * `sender` must have a balance of at least `amount`.
     */
    function _transferProtocolFee(uint256 amount) internal virtual {
        _beforeTokenTransfer(address(this), walletContractAddress, amount);
        uint256 senderBalance = protocolFeeBalance;
        require(senderBalance >= amount, "Insufficient Protocol Fee Balance!");
        protocolFeeBalance = protocolFeeBalance.sub(amount);
        _balances[walletContractAddress] = 
            _balances[walletContractAddress].add(
            amount);
        
        emit Transfer(address(this), walletContractAddress, amount);
        _afterTokenTransfer(address(this), walletContractAddress, amount);
    }

   
}
