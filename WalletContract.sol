// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./chainlink/KeeperCompatibleInterface.sol";

/// @title Wallet Contract
/// @author Yotta21

contract WalletContract {
    /* ================ State Variables ================== */

    // address of contract creater
    address public owner;
    // address of manager
    address public manager;
    // address of other wallet contract
    address public secondWalletContract;
    // max limit for balance of wallet contract address
    //uint256 public constant LIMIT = 92160 * 10**18;
    // importing otta token methods
    ERC20 private ottaToken;
    uint256 public counter;
    uint256 public lastTimestamp;
    uint256 public time = 4 * 31556926 seconds; // 1 yaer 31556926 second
    /*================== Modifiers =====================*/
    /*
     * Throws if the sender is not owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner");
        _;
    }

    /* ================ Constructor ================== */
    constructor(address _manager, address _ottaAddress) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        require(_ottaAddress != address(0), "zero address");
        ottaToken = ERC20(_ottaAddress);
        lastTimestamp = block.timestamp;
    }

    /* ================ Functions ================== */
    /* ================ External Functions ================== */
     function setManager(address _manager) public onlyOwner returns(address){
        require(_manager != address(0), "zero address");
        manager = _manager;
        return manager;
    }
    /*
     * Notice: Setting wallet contract
     * Param:
     * '_newWalletContract' The wallet contract
     */
    function setNewWalletContract(address _newWalletContract)
        external
        onlyOwner
    {
        require(_newWalletContract != address(0), "zero address");
        secondWalletContract = _newWalletContract;
    }

    /*
     * Notice: Setting new owner address
     * Param:
     * '_newOwner' The owner address
     */
    /*function setOwner(address _newOwner) external onlyOwner {
        require(msg.sender == owner, "Only Owner");
        require(_newOwner != address(0), "zero address");
        owner = _newOwner;
    }*/

    /*
     * Notice: Withdraw otta token to owner
     */
    function withdrawOtta() external onlyOwner {
        if (counter == 4) {
            bool _success = ottaToken.transfer(
                msg.sender,
                ottaToken.balanceOf(address(this)) 
            );
            require(_success, "Otta Token transfer failed");
        } else {
            require((block.timestamp - lastTimestamp) >= time , "not epoch");
            lastTimestamp = block.timestamp;
            counter += 1;
            bool _success1 = ottaToken.transfer(
                msg.sender,
                ottaToken.balanceOf(address(this)) 
            );
            require(_success1, "Otta Token transfer failed");
        }
    }

    /*
     * Notice: This method checks 'upkeepNeeded'
     */
    /*function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = ottaToken.balanceOf(address(this)) > LIMIT;
        performData = checkData;
    }*/

    /*
     * Notice: If upKeepNeeded true, execute sendOtta method
     */
    /*function performUpkeep(bytes calldata performData) external override {
        sendOtta();
        performData;
    }*/

    /* ================ Internal Functions ================== */
    /*
     * Notice: If balance of this contract more than LIMIT it sends all otta token to secondWalletContract
     */
    /*function sendOtta() internal {
        bool _success = ottaToken.transfer(
            secondWalletContract,
            ottaToken.balanceOf(address(this))
        );
        require(_success, "Otta Token transfer failed");
    }*/
}
