// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IDividend} from "./interfaces/IDividend.sol";
import {IWeth} from "./interfaces/IWeth.sol";

/// @title Dividend
/// @author Yotta21

contract Dividend is IDividend {
    using SafeMath for uint256;

    /* =================== Event ====================== */

    event ManagerSetted(address _manager);
    event DividendRequestingAddressSetted(address _dividendRequestingAddress);

    /* =================== State Variables ====================== */

    // address of contract creater
    address public owner;
    // address of manager
    address public manager;
    // address of otta token
    address public ottaTokenAddress;
    // address of LockedOtta
    address public lockedOtta;
    // address of dividend Requesting address
    address public dividendRequestingAddress;
    // total number of wallets locking otta tokens
    uint256 public walletCounter;
    // total locked otta token amount
    uint256 public totalLockedOtta;
    // total ethereum to dividend
    uint256 public totalEthDividend;
    // max int value
    uint256 public constant MAX_INT = 2**256 - 1;
    // state of sets in contract
    bool public isLockingEpoch;
    bool public isOttaTokenSetted;
    bool public isTreasureSetted;
    //bool public isManagerSetted;
    // holds relation of address and locked otta token amount
    mapping(address => uint256) private locked;
    // importing otta token methods
    ERC20 public ottaToken;

    /* ================ Modifier ================== */

    /*
     * Throws if the sender is not owner or manager
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner or Manager");
        _;
    }

    /* =================== Constructor ====================== */

    constructor(
        address _manager,
        address _ottaTokenAddress,
        address _lockedOtta
    ) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        isLockingEpoch = false;
        require(_ottaTokenAddress != address(0), "zero address");
        ottaTokenAddress = _ottaTokenAddress;
        ottaToken = ERC20(ottaTokenAddress);
        require(_lockedOtta != address(0), "zero address");
        lockedOtta = _lockedOtta;
    }

    /* =================== Functions ====================== */
    /* =================== Public Functions ====================== */
    /*
     * Notice: Setting manager address
     * Param:
     * '_manager' address of ethereum vault
     */
    function setManager(address _manager) public onlyOwner returns (address) {
        require(_manager != address(0), "zero address");
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }
    
    
    /*
     * Notice: Setting dividend owner address
     * Param:
     * '_dividendOwnerAddress' address of dividend owner
     */
    function setDividendRequestingAddress(address _dividendRequestingAddress) public onlyOwner returns (address) {
        require(_dividendRequestingAddress != address(0), "zero address");
        dividendRequestingAddress = _dividendRequestingAddress;
        emit DividendRequestingAddressSetted(dividendRequestingAddress);
        return manager;
    }

    /*
     * Notice: Returns locked otta amount of user
     * Param:
     * '_userAddress' The address of user
     */
    function getLockedAmount(address _userAddress)
        public
        view
        returns (uint256 lockedAmount)
    {
        return locked[_userAddress];
    }

    /* =================== External Functions ====================== */
    receive() external payable {}

    /*
     * Notice: Setting locking epoch
     * Param:
     * 'epoch' The state of locking epoch
     */
    function setEpoch(bool epoch)
        external
        override
        returns (bool state, uint256 totalEth)
    {
        require(msg.sender == ottaTokenAddress, "Only Otta");
        isLockingEpoch = epoch;
        if (isLockingEpoch) {
            totalEthDividend = address(this).balance;

            uint256 _amount = ottaToken.balanceOf(lockedOtta);
            locked[owner] = _amount;
            uint256 _ottaAmount = ottaToken.balanceOf(address(this));
            totalLockedOtta = _ottaAmount.add(_amount);
            walletCounter += 1;
            emit OttaTokenLocked(owner, _amount);
        }
        return (isLockingEpoch, totalEthDividend);
    }

    /*
     * Notice: recives otta token to lock
     * Param:
     * 'amount' The otta token amount to lock
     */
    function lockOtta(uint256 amount) external {
        require(isLockingEpoch, "Not Epoch");
        locked[msg.sender] = locked[msg.sender].add(amount);
        totalLockedOtta = totalLockedOtta.add(amount);
        walletCounter += 1;
        bool success = ottaToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Transfer failed");
        emit OttaTokenLocked(msg.sender, amount);
    }

    /*
     * Notice: calculates dividend amount of user
     *         sends dividend to user
     *         user withdraw otta token
     */
    function getDividend() external {
        require(!isLockingEpoch, "Not Dividend Epoch");
        require(locked[msg.sender] != 0, "Locked Otta not found");
        address payable _userAddress = payable(msg.sender);
        require(_userAddress != address(0), "zero address");
        uint256 _ottaQuantity = locked[msg.sender];
        locked[msg.sender] = 0;
        walletCounter -= 1;
        uint256 _percentage = (_ottaQuantity.mul(10**18)).div(totalLockedOtta);
        uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(
            10**18
        );
        _userAddress.transfer(_dividendQuantity);
        bool success = ottaToken.transfer(msg.sender, _ottaQuantity);
        require(success, "transfer failed");
    }

    /*
     * Notice: calculates dividend amount of owner
     *         sends dividend to owner
     *         owner withdraw ether
     *         called when we lose the owner
     */
    function getDividendRequesting() external override {
        require(msg.sender == ottaTokenAddress, "Only Otta");
        address payable _userAddress = payable(dividendRequestingAddress);
        require(_userAddress != address(0), "zero address");
        uint256 _ottaQuantity = locked[owner];
        locked[owner] = 0;
        walletCounter -= 1;
        uint256 _percentage = (_ottaQuantity.mul(10**18)).div(totalLockedOtta);
        uint256 _dividendQuantity = (_percentage.mul(totalEthDividend)).div(
            10**18
        );
        _userAddress.transfer(_dividendQuantity);
    }
}
