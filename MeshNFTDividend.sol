// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IMeshNFTDividend } from "./interfaces/IMeshNFTDividend.sol";
import { IWeth } from "./external/IWeth.sol";
import { IDividend } from "./interfaces/IDividend.sol";
import { ICurrentVotes } from "./interfaces/ICurrentVotes.sol";

/// @title MeshNFTDividend
/// @author Yotta21
/// @notice The process of entering and exiting the dividend takes place.
contract MeshNFTDividend is IMeshNFTDividend {
  using SafeMath for uint256;

  /* =================== State Variables ====================== */
  address public ottaAddress;
  address public timelockForOtta;
  /// @notice Total number of wallets lock
  uint256 public meshNFTHoldCounter;
  /// @notice Total ethereum to dividend for 
  uint256 public totalEthDividend;
  /// @notice Period counter for dividend
  uint256 public periodCounterMeshNFT;
  /// @notice Max integer value
  uint256 public constant MAX_INT = 2**256 - 1;
  /// @notice State of sets in this contract
  bool public isLockingEpoch;
  bool public isLockDividend;
  /// @notice dönemde kilitledi mi
  mapping(uint => mapping(uint256 => bool)) private locked;
  /// @notice Means the yotta dividend share right of the user within the period
  mapping(uint => mapping(uint256 => bool))
    public receiveDividendCoordinator;
  /// @notice Importing current votes methods
  ICurrentVotes public meshVotes;
  ICurrentVotes public ottaVotes;
  IDividend public dividend;
  ERC721 public mesh;
  ERC20 public eth;

  /* =================== Constructor ====================== */
  constructor(address _ottaAddress, address _meshAddress, address _ethAddress) {
    isLockingEpoch = true;
    ottaAddress = _ottaAddress;
    ottaVotes = ICurrentVotes(_ottaAddress);
    meshVotes = ICurrentVotes(_meshAddress);
    mesh = ERC721(_meshAddress);
    eth = ERC20(_ethAddress);
  }

  /* =================== Functions ====================== */
  //receive() external payable {}

  /* =================== External Functions ====================== */
  /// @inheritdoc IMeshNFTDividend
  function setEpochForMeshNFTDividend(bool epoch)
    external
    override
    returns (bool state, uint256 totalEth)
  {
    require(msg.sender == ottaAddress, "Only Otta");
    isLockingEpoch = epoch;
    if (isLockingEpoch) {
      totalEthDividend = eth.balanceOf(address(this));
      meshNFTHoldCounter = 0;
      periodCounterMeshNFT += 1;
    }
    return (isLockingEpoch, totalEthDividend);
  }

  /// @notice
  function lock(uint _id) external {
    require(isLockingEpoch, "Not epoch");
    require(dividend.getPeriod() != 0, "not start");
    require(mesh.ownerOf(_id) == msg.sender, "take airdrop");
    //require(mesh.balanceOf(msg.sender) != 0, "not has airdrop");
    require(!locked[_id][periodCounterMeshNFT], "locked");
    locked[_id][periodCounterMeshNFT] = true;
    meshNFTHoldCounter += 1;
  }

  /// @notice calculates dividend amount of user
  /// @dev Transfers dividends to the user
  function getDividend(address _account, uint _id) external override {
    require(!isLockingEpoch, "Not Dividend Epoch");
    require(locked[_id][periodCounterMeshNFT], "not locked");
    require(mesh.ownerOf(_id)==_account, "not nft hold");
    require(
      !receiveDividendCoordinator[_id][periodCounterMeshNFT],
      "Already received"
    );
    address payable _userAddress = payable(_account);
    require(_userAddress != address(0), "zero address");
    receiveDividendCoordinator[_id][periodCounterMeshNFT] = true;
    uint256 _dividendQuantity = totalEthDividend.div(meshNFTHoldCounter);
    eth.transfer(_userAddress, _dividendQuantity);
  }

  /// @notice Setting dividend contract address
  /// @param _dividendAddress address of dividend contract
  function setDividend(address _dividendAddress) public returns (address) {
    dividend = IDividend(_dividendAddress);
    return _dividendAddress;
  }
}
