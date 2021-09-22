// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import {IPoolTokenAdapter} from "./interfaces/IPoolTokenAdapter.sol";
import "./interfaces/ITaum.sol";
import "./chainlink/KeeperCompatibleInterface.sol";
import "./interfaces/IEthereumVault.sol";
import "./interfaces/IPrice.sol";

/// @title Taum Token
/// @author Yotta21

contract Taum is Context, IERC20, IERC20Metadata, ITaum {
    using SafeMath for uint256;

    /*================== State Variables ===================*/

    // token name for taum token
    string private _name;
    // token symbol for taum token
    string private _symbol;
    // token decimals for taum token
    uint8 private _decimals;
    // total supply
    uint256 private _totalSupply;
    // yearly percent of total supply
    uint256 private constant YEARLY_VALUE = 10368 * 10**14;
    // Chainlink keeper call time
    uint256 public immutable interval;
    // Block Timestamp
    uint256 public lastTimeStamp;
    // address of reward contract
    address public rewardAddress;
    // Address of the Ethereum Pool  
    address private ethPoolAddress;
    // Address of contract creator
    address public ownerAddress;
    // address of manager
    address public manager;
    // Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) private _allowances;
    // Official record of token balances for each account
    mapping(address => uint256) private _balances;
    // importing PriceV1 interface as priceV1
    IPrice private price;
    // importing Ethereum vault interface as ethVault
    IEthereumVault private ethVault;
    // importing Pool Token Adapter contract interface as poolTokenAdapter
    //IPoolTokenAdapter private poolTokenAdapter;

      /* ================ Modifier ================== */
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
        address payable _rewardAddress,
        address _priceAddress
    ) {
        ownerAddress = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        /*require(_poolTokenAdapter != address(0), "zero address");
        poolTokenAdapterAddress = _poolTokenAdapter;
        poolTokenAdapter = IPoolTokenAdapter(poolTokenAdapterAddress);*/
        require(_rewardAddress != address(0), "zero address");
        rewardAddress = _rewardAddress;
        require(_priceAddress != address(0), "zero address");
        price = IPrice(_priceAddress);
        interval = _interval;
        lastTimeStamp = block.timestamp;
        _mint(ownerAddress, (10000 * 10 ** 18));
    }

    /*================== Public Functions =====================*/
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
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
        returns (address _newPriceAddress)
    {
        require(_priceAddress != address(0), "zero address");
        price = IPrice(_priceAddress);
        return (_priceAddress);
    }
    
     function setVault(address _vaultAddress)
        public
        onlyOwner
        returns (address _newVaultAddress)
    {
        require(_vaultAddress != address(0), "zero address");
        ethVault = IEthereumVault(_vaultAddress);
        return (_vaultAddress);
    }

     function setEthPool(address _ethPoolAddress)
        public
        onlyOwner
        returns (address _newEthPoolAddress)
    {
        require(_ethPoolAddress != address(0), "zero address");
        ethPoolAddress = _ethPoolAddress;
        return (_ethPoolAddress);
    }

    /*================== External Functions =====================*/
    /*
     * Notice: function called when otta token sale is made to the system
     * Param: 'amount' quantity of taum token . It must be wei type (10**18)
     */
    function receiver(uint256 amount) external override {  
        address payable _userAddress = payable(msg.sender);
        uint256 accountBalance = _balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        bool successTransfer = transfer(address(this), amount);
        require(successTransfer, "Transfer failed");
        (,,uint256 _taumPrice) = price.getTaumPrice();
        uint256 _ethAmount = amount.mul(_taumPrice).div(10**18);
        bool statusInvestment = ethVault.withdraw(_userAddress, _ethAmount);
        require(statusInvestment, "Insufficient Ether");
        _burn(address(this), amount);
    }

    /*
     *  Notice: function to call before _mint functions
     */
    function tokenMint(address recipient, uint256 amount) external override {
        require(msg.sender == ethPoolAddress, "Only Ethereum Pool");
        _mint(recipient, amount);
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
     * Notice: Chainlink Keeper method calls mintProtocol method
     */
    function performUpkeep(bytes calldata performData) external {
        lastTimeStamp = block.timestamp;
        mintProtocolFee();
        performData;
    }

    /*================== Internal Functions =====================*/
    /*
     *  Notice: calculate protocol fee and mint the reward contract
     */
    function mintProtocolFee() internal {
        uint256 _protocolFee = (_totalSupply.mul(YEARLY_VALUE)).div(100).div(8766 * 10 ** 18);
        (,,uint256 _taumPrice) = price.getTaumPrice();
        uint256 _feeQuantity = (_taumPrice.mul(_protocolFee)).div(10**18);
        ethVault.withdraw(payable(rewardAddress), _feeQuantity);
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
}
