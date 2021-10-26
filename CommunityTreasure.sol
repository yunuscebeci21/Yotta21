// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Treasure
/// @author Yotta21

contract CommunityTreasure {
    /* ================ Events ================== */

    event ManagerSetted(address _manager);
    event OttaSetted(address _ottaAddress);
    event CommunityContractSetted(address _communityContract);
    event WithdrawOttaSetted(address _recipient, uint256 _ottaAmount);

    /* ================ State Variables ================== */

    // address of contract creater
    address public owner;
    // address of manager
    address public manager;
    // address of community contract
    address public communityContract;
    // for withdraw counter
    uint256 public counter;
    // for last withdraw time
    uint256 public lastTimestamp;
    // locked for 4 years 
    uint256 public time = 4 * 31556926 seconds; // 1 yaer 31556926 second
    // set status of this contract
    bool public isManagerSetted;
    bool public isOttaSetted;
    bool public isCommunityContractSetted;
    // importing otta token methods
    ERC20 private ottaToken;

    /*================== Modifiers =====================*/

    /*
     * Throws if the sender is not owner or manager
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == manager, "Only Owner or Manager");
        _;
    }

    /* ================ Constructor ================== */

    constructor(address _manager) {
        owner = msg.sender;
        require(_manager != address(0), "zero address");
        manager = _manager;
        lastTimestamp = block.timestamp;
    }

    /* ================ Functions ================== */
    /* ================ Public Functions ================== */

    /*
     * Notice: Setting manager address
     * Param:
     * '_manager' address of manager
     */
    function setManager(address _manager) public onlyOwner returns (address) {
        require(!isManagerSetted, "Already ssetted");
        require(_manager != address(0), "zero address");
        isManagerSetted = true;
        manager = _manager;
        emit ManagerSetted(manager);
        return manager;
    }

    /*
     * Notice: Setting otta contract address
     * Param:
     * '_ottaAddress' address of otta contract address
     */
    function setOtta(address _ottaAddress) public onlyOwner returns (address) {
        require(!isOttaSetted, "Already setted");
        require(_ottaAddress != address(0), "zero address");
        isOttaSetted = true;
        ottaToken = ERC20(_ottaAddress);
        emit OttaSetted(_ottaAddress);
        return _ottaAddress;
    }

    /*
     * Notice: Setting community contract address
     * Param:
     * '_communityContract' address of community contract address
     */
    function setCommunityContract(address _communityContract)
        public
        onlyOwner
        returns (address)
    {
        //require(!isCommunityContractSetted, "Already setted");
        require(_communityContract != address(0), "zero address");
        //isCommunityContractSetted = true;
        communityContract = _communityContract;
        emit CommunityContractSetted(communityContract);
        return communityContract;
    }

    /*
     * Notice: Withdraw otta token to owner or manager
     *         Withdrawn every 4 years within 16 years (locked for 4 years)
     *         and then withdrawn at any time
     */
    function withdrawOtta() public onlyOwner {
        if (counter == 4) {
            bool _success = ottaToken.transfer(
                communityContract,
                ottaToken.balanceOf(address(this))
            );
            require(_success, "Otta Token transfer failed");
            emit WithdrawOttaSetted(msg.sender, ottaToken.balanceOf(address(this)));
        } else {
            require((block.timestamp - lastTimestamp) >= time, "not epoch");
            lastTimestamp = block.timestamp;
            counter += 1;
            bool _success1 = ottaToken.transfer(
                communityContract,
                ottaToken.balanceOf(address(this))
            );
            require(_success1, "Otta Token transfer failed");
            emit WithdrawOttaSetted(msg.sender, ottaToken.balanceOf(address(this)));
        }
    }
}
