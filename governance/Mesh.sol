// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ICurrentVotes } from "../interfaces/ICurrentVotes.sol";
import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
contract NFT21 is
  ERC721URIStorage,
  ICurrentVotes,
  KeeperCompatibleInterface
{
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }
  uint256 public unlockedMeshSupply;
  uint256 public totalMeshSupply; 
  uint256 public lastTimeStamp;
  uint256 public cost;
  uint256 public firstSupply; 
  address public dividend;
  address public ottaTimelock;
  address public owner;
  mapping(address => address) public delegates;
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
  mapping(address => uint32) public numCheckpoints;
  string public constant TOKENURI = "https://ipfs.io/ipfs/QmcUGJ838Y5MoyasPfC3HVMYJP4obgyxMchkP7p4aWnhTz";
  bool public isSetCost;
  ERC20 public dai;
  constructor(address _dai) ERC721("NFT21", "NFT21") {
    owner = msg.sender;
    dividend = owner;
    cost = 1*10**18;
    dai = ERC20(_dai);
    lastTimeStamp = block.timestamp;
     
  }
  function setCostByOwner(uint _newCost) external {
    require(msg.sender == owner, "only owner");
    require(!isSetCost, "already setted cost");
    isSetCost = true;
    cost = _newCost;
  }
  function setCostByTimelock(uint _newCost) external {
    require(msg.sender == ottaTimelock, "only otta timelock");
    cost = _newCost;
  }
  function firstSupplyMint(uint _amountNFT, address _recipient) external { // owner veya yine owner ın gireceği bir adres olabilir
    require(msg.sender==owner, "only owner");
    require(firstSupply < 2000, "first supply mint finish");
    firstSupply += _amountNFT;
    for(uint i=0; i<_amountNFT; i++){ 
        mintNFT(_recipient);
    }   
  }
  function requirementsToNFT(uint256 _amount) external {
    require(balanceOf(msg.sender) == 0, "Recipient has NFt");
    require(_amount >= cost, "need to mint at 1 NFT"); 
    unlockedMeshSupply = unlockedMeshSupply + 1; 
    totalMeshSupply = totalMeshSupply + 1; 
    require(
      unlockedMeshSupply < 1000*10**18,
      "max Mesh sell finish in one year"
    );
    require(
      totalMeshSupply < 18000*10**18,
      "max Mesh limit exceeded"
    );
    bool success = dai.transferFrom(msg.sender, dividend, cost); 
    require(success,"transfer failed");    
    mintNFT(msg.sender);
  }
  function setDividend(address _dividend) external { 
    require(msg.sender==owner,"only owner");
    dividend = _dividend;
  }
  function performUpkeep(bytes calldata performData) external override {
    require((block.timestamp - lastTimeStamp) >= 31556926, "not epoch"); 
    require(totalMeshSupply < 18000*10**18, "mesh total supply");
    lastTimeStamp = block.timestamp;
    unlockedMeshSupply = 0;
    performData;
  }
  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    upkeepNeeded = (block.timestamp - lastTimeStamp) >= 31556926; // 1 yıl olarak değiştir
    performData = checkData;
  }
  function getCurrentVotes(address account)
    external
    view
    override
    returns (uint256)
  {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }
  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }
  function mintNFT(address _account) internal {
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      _mint(_account, newItemId);
      _setTokenURI(newItemId, TOKENURI);
  }
  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator);
    delegates[delegator] = delegatee;
    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }
  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0
          ? checkpoints[srcRep][srcRepNum - 1].votes
          : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepNew);
      }
      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0
          ? checkpoints[dstRep][dstRepNum - 1].votes
          : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepNew);
      }
    }
  }
  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(
      block.number,
      "Comp::_writeCheckpoint: block number exceeds 32 bits"
    );
    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }
  }
  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    chainId = block.chainid;
    return chainId;
  }
  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }
}
