pragma solidity ^0.5.16;

import "./SafeMath.sol";

contract TreasuryVester {
    using SafeMath for uint;

    address public otta;
    address public recipient;

    uint public vestingAmount;
    uint public vestingBegin;
    uint public vestingCliff;
    uint public vestingEnd;

    uint public lastUpdate;
    
    bool public isOttaSetted;

    constructor(
        address recipient_,
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_
    ) public {
        require(vestingBegin_ >= block.timestamp, 'TreasuryVester::constructor: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'TreasuryVester::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'TreasuryVester::constructor: end is too early');

        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }
    
    function setOtta(address otta_) public {
        require(!isOttaSetted, 'TreasuryVester::setOtta: already setted');
        isOttaSetted = true;
        otta = otta_;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'TreasuryVester::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'TreasuryVester::claim: not time yet');
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = IOtta(otta).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IOtta(otta).transfer(recipient, amount);
    }
}

interface IOtta {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}