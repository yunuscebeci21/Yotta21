// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IReward} from "./interfaces/IReward.sol";
import {IWeth} from "./interfaces/IWeth.sol";

/// @title Reward
/// @author Yotta21

contract Reward is IReward {
    using SafeMath for uint256;
    /* =================== State Variables ====================== */
    // address of contract creater
    address public owner;
    // address of manager
    address public manager;
    // address of otta token
    address public ottaTokenAddress;
    //
    address public walletContractAddress;
    // total number of wallets locking otta tokens
    uint256 public walletCounter;
    // total locked otta token amount
    uint256 public totalLockedOtta;
    // total ethereum to reward
    uint256 public totalEthReward;
    // state of locking epoch
    bool public isLockingEpoch;
    // holds relation of address and locked otta token amount
    mapping(address => uint256) private locked;
    // set state of otta token
    bool public isOttaTokenSetted = false;
    bool public isWalletContractSetted = false;
    // importing otta token methods
    ERC20 public ottaToken;

    /* ================ Modifier ================== */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /* =================== Constructor ====================== */

    constructor(address _manager) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        isLockingEpoch = false;
    }

    /* =================== Functions ====================== */
    /* =================== Public Functions ====================== */
    function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        owner = manager;
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

    /*
     * Notice: Setting address of otta token
     * Param:
     * '_ottaTokenAddress' The address of otta token
     */
    function setOttaToken(address _ottaTokenAddress)
        public
        onlyOwner
        returns (address newOttaTokenAddress)
    {
        require(!isOttaTokenSetted, "Already setted");
        require(_ottaTokenAddress != address(0), "zero address");
        ottaTokenAddress = _ottaTokenAddress;
        ottaToken = ERC20(ottaTokenAddress);
        isOttaTokenSetted = true;
        emit OttaTokenSetted(ottaTokenAddress);
        return (ottaTokenAddress);
    }

    function setWalletContract(address _walletContractAddress)
        public
        onlyOwner
        returns (address)
    {
        require(!isWalletContractSetted, "Already setted");
        require(_walletContractAddress != address(0), "zero address");
        walletContractAddress = _walletContractAddress;
        isWalletContractSetted = true;
        emit WalletContractSetted(walletContractAddress);
        return (walletContractAddress);
    }

    /* =================== External Functions ====================== */
    receive() external payable{}
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
            totalEthReward = address(this).balance;

            uint256 _amount = ottaToken.balanceOf(walletContractAddress);
            locked[owner] += _amount;
            totalLockedOtta += _amount;
            walletCounter += 1;
            emit OttaTokenLocked(owner, _amount);
        }
        return (isLockingEpoch, totalEthReward);
    }

    /*
     * Notice: recives otta token to lock
     * Param:
     * 'amount' The otta token amount to lock
     */
    function lockOtta(uint256 amount) external {
        require(isLockingEpoch, "Not Epoch");
        locked[msg.sender] += amount;
        totalLockedOtta += amount;
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
     * Notice: calculates reward amount of user
     *         sends reward to user
     *         user withdraw otta token
     */
    function getReward() external {
        require(!isLockingEpoch, "Not Reward Epoch");

        require(locked[msg.sender] != 0, "Locked Otta not found");
        address payable _userAddress = payable(msg.sender);
        require(_userAddress != address(0), "zero address");
        uint256 _ottaQuantity = locked[msg.sender];
        locked[msg.sender] = 0;
        walletCounter -= 1;
        uint256 _prePercentage = _ottaQuantity.mul(100);
        uint256 _percentage = (_prePercentage.mul(10**18)).div(totalLockedOtta);
        uint256 _preRewardQuantity = (_percentage.mul(totalEthReward)).div(
            10**18
        );
        uint256 _rewardQuantity = _preRewardQuantity.div(100);
        _userAddress.transfer(_rewardQuantity);
        if (msg.sender != owner) {
            bool success = ottaToken.transfer(msg.sender, _ottaQuantity);
            require(success, "transfer failed");
        }
    }

    function getRewardOwner() external onlyOwner{
        require(!isLockingEpoch, "Not Reward Epoch");

        require(locked[owner] != 0, "Locked Otta not found");
        address payable _userAddress = payable(msg.sender);
        require(_userAddress != address(0), "zero address");
        uint256 _ottaQuantity = locked[owner];
        locked[owner] = 0;
        walletCounter -= 1;
        uint256 _prePercentage = _ottaQuantity.mul(100);
        uint256 _percentage = (_prePercentage.mul(10**18)).div(totalLockedOtta);
        uint256 _preRewardQuantity = (_percentage.mul(totalEthReward)).div(
            10**18
        );
        uint256 _rewardQuantity = _preRewardQuantity.div(100);
        _userAddress.transfer(_rewardQuantity);
    }
}
