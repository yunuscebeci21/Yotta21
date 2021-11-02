// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IDividend} from "./interfaces/IDividend.sol";
import {IPrice} from "./interfaces/IPrice.sol";


/// @title Otta
/// @author Yotta21
contract Otta is Context, IERC20, IERC20Metadata {

    using SafeMath for uint256;

    /* ================ Events ================== */

    event ManagerSetted(address _manager);
    event PriceSetted(address _priceAddress);
    event DividendSetted(address _dividendAddress);
    event IntervalSetted(uint256 _interval);
    event DividendLockDaySetted(uint256 _dividendDay, uint256 _lockDay);
    event OttaTokenPurchased(address indexed _resipient, uint256 _ottaAmount);

    /* ================ State Variables ================== */

    // address of owner
    address public ownerAddress;
    // address of manager
    address public manager;
    // address of dividend contract
    address public dividendAddress;
    // address of lockedOtta contract
    address private lockedOtta;
    // token name for otta token
    string private _name;
    // token symbol for otta token
    string private _symbol;
    // token decimals for otta token
    uint8 private _decimals;
    // day counter for dividend lock time and unlock time
    uint16 public dividendDayCounter;
    // total supply of tokens
    uint256 private _totalSupply;
    // total locked supply, set zero first
    uint256 public lockedSupply;
    // total unlocked supply, set zero first
    uint256 public unlockedSupply;
    // Chainlink keeper call time
    uint256 public interval;
    // Block Timestamp
    uint256 public lastTimeStamp;
    // Dividend day
    uint256 public dividendDay;
    // Lock day
    uint256 public lockDay;
    // When the Dividend counter is 0
    uint256 public dividendTime;
    // daily cumulative community treasure fee
    uint256 public lockedOttaFeeBalance;
    // max mint token - total otta supply
    uint256 public constant TOTAL_OTTA_AMOUNT = 55 * 10**24;
    // mint amount for ico
    uint256 public constant ICO_SUPPLY = 24040 * 10**20;
    // otta contract set status
    bool public isPriceSetted;
    bool public isDividendSetted;
    // Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) private _allowances;
    // Official record of token balances for each account
    mapping(address => uint256) private _balances;
    // importing dividend contract interface as dividend
    IDividend public dividend;
    // importing price contract interface as price
    IPrice public price;

    /*================== Modifiers =====================*/

    /*
     * Throws if the sender is not owner or manager
     */
    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress || msg.sender == manager,
            "Only Owner or Manager"
        );
        _;
    }

    /*=============== Constructor ========================*/

    constructor(
        address _manager,
        string memory name_,
        string memory symbol_,
        uint256 _interval,
        address _lockedOtta
    ) {
        ownerAddress = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        interval = _interval;
        lastTimeStamp = block.timestamp;
        dividendDay = 28;
        lockDay = 2;
        require(_lockedOtta != address(0), "zero address");
        lockedOtta = _lockedOtta;
        _mint(address(this), TOTAL_OTTA_AMOUNT);
        _transfer(address(this), ownerAddress, ICO_SUPPLY.mul(80).div(100));
        _transfer(address(this), lockedOtta, ICO_SUPPLY.mul(20).div(100));
        lockedSupply = _totalSupply.sub(ICO_SUPPLY);
    }

    /* ================ Functions ================== */
    /*================== Public Functions =====================*/

    /* Notice: Setting manager address
     * Params:
     * '_manager' The manager address.
     */
    function setManager(address _manager) public onlyOwner returns (address) {
        require(_manager != address(0), "zero address");
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
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
        require(_priceAddress != address(0), "zero address");
        isPriceSetted = true;
        price = IPrice(_priceAddress);
        emit PriceSetted(_priceAddress);
        return _priceAddress;
    }

    /* Notice: Setting dividend contract address
     * Params:
     * '_dividendAddress' The dividend contract address.
     */
    function setDividend(address _dividendAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isDividendSetted, "Already setted");
        require(_dividendAddress != address(0), "zero address");
        isDividendSetted = true;
        dividendAddress = _dividendAddress;
        dividend = IDividend(dividendAddress);
        emit DividendSetted(dividendAddress);
        return dividendAddress;
    }

    /* Notice: Setting keeper trigger time methods
     * Params:
     * '_interval' The new keeper trigger time.
     */
    function setInterval(uint256 _interval) public onlyOwner returns(uint256){
        require(_interval != 0, "zero interval");
        interval = _interval;
        emit IntervalSetted(interval);
        return interval;
    }

    /* Notice: Setting dividend and lock day
     * Params:
     * '_dividendDay' The new dividend day
     * '_lockDay' The new lock day
     */
    function setDividendLockDay(uint256 _dividendDay, uint256 _lockDay) public onlyOwner returns(uint256, uint256){
        require(_dividendDay != 0 && _lockDay !=0, "zero day");
        dividendDay = _dividendDay;
        lockDay = _lockDay;
        emit DividendLockDaySetted(dividendDay, lockDay);
        return (dividendDay, lockDay);
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
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
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

    /*================== External Functions =====================*/

    /*
     * Notice: The function to be triggered when the otta token will buy
     * The amount of ethereum sent is calculated based on the otta price.
     * Otta token is transferred to the caller and the protocol.
     */
    receive() external payable {
        uint256 _ethAmount = msg.value;
        require(msg.sender != address(0), "zero address");
        require(_ethAmount != 0, "insufficient eth amount");
        address _userAddress = msg.sender;
        uint256 _ottaPrice = price.getOttaPrice();
        uint256 _tokens = (_ethAmount.mul(10**18)).div(_ottaPrice);
        uint256 _userAllowance = 0;
        if (_tokens >= (1000 * 10**18)) {
            _userAllowance = _ethAmount.mul(2).div(100);
            payable(_userAddress).transfer(_userAllowance);
        }
        uint256 _lockedOttaFee = _tokens.mul(25).div(100);
        payable(dividendAddress).transfer(_ethAmount.sub(_userAllowance));
        _transferFromContract(msg.sender, _tokens);
        _transferTreasureFee(_lockedOttaFee);
        emit OttaTokenPurchased(msg.sender, _tokens);
    }

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
        require((block.timestamp - lastTimeStamp) > interval, "not epoch");
        lastTimeStamp = block.timestamp;
        unlocked();
        performData;
    }

    /*================== Internal Functions =====================*/
    /* Notice: Triggers every interval time
     * Unlocks  9000 tokens each time triggered
     * Unlocked tokens are split into two: 'unlockedSupply' and 'lockedOttaFeeBalance'
     * Buy is made from 'unlockedSupply'
     * Mint for lockedOtta from 'lockedOttaFeeBalance'
     */
    function unlocked() internal {
        if (lockedSupply == 0) {
            dividendDayCounter += 1;
            if (dividendDayCounter == dividendDay) {
                dividend.setEpoch(true);
            }
            if (dividendDayCounter == lockDay + dividendDay) {
                dividend.setEpoch(false);
                dividendDayCounter = 0;
                dividendTime = block.timestamp;
                dividend.getDividendRequesting();
            }
        } else {
            lockedSupply = lockedSupply.sub(9000 * 10**18);
            unlockedSupply = unlockedSupply.add(7200 * 10**18);
            lockedOttaFeeBalance = lockedOttaFeeBalance.add(1800 * 10**18);
            dividendDayCounter += 1;
            if (dividendDayCounter == dividendDay) {
                dividend.setEpoch(true);
            }
            if (dividendDayCounter == lockDay + dividendDay) {
                dividend.setEpoch(false);
                dividendDayCounter = 0;
                dividendTime = block.timestamp;
                dividend.getDividendRequesting();
            }
        }
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
        _transfer(address(this), recipient, amount);
        _afterTokenTransfer(address(this), recipient, amount);
    }

    /*
     * Notice: Transfer function written for the lockedOtta to transfer
     * from "lockedOttaFeeBalance" after buying otta tokens
     * 'sender' this contract
     * 'recipient' lockedOtta contract
     * Requirements:
     * 'recipient' cannot be the zero address.
     * `sender` must have a balance of at least `amount`.
     */
    function _transferTreasureFee(uint256 amount) internal virtual {
        _beforeTokenTransfer(address(this), lockedOtta, amount);
        uint256 senderBalance = lockedOttaFeeBalance;
        require(senderBalance >= amount, "Insufficient Protocol Fee Balance!");
        lockedOttaFeeBalance = lockedOttaFeeBalance.sub(amount);
        _transfer(address(this), lockedOtta, amount);
        _afterTokenTransfer(address(this), lockedOtta, amount);
    }
}
