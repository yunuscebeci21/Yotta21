// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title AirDrop
/// @author Yotta21
contract AirDrop {
  using SafeMath for uint256;

  address public owner;
  address public ottaAddress;
  address public meshAddress;
  mapping(address => mapping(uint256 => bool)) public isAirDrop;
  ERC20 public otta;
  ERC721 public mesh;
  bool public isStart;

  constructor(address _ottaAddress, address _meshAddress) {
    require(_ottaAddress != address(0), "zero address");
    owner = msg.sender;
    ottaAddress = _ottaAddress;
    meshAddress = _meshAddress;
    otta = ERC20(ottaAddress);
    mesh = ERC721(meshAddress);
  }

  // mesh den map i oku adresin alıp almadığının kontrolünü yap ************************
  // mesh contract - mapping id => msg.sender
  // airdrop contract - read func. - girilen id nin map deki karşılığı msg.sender'a eşit mi?
  // kaç tane nft varsa o kadar otta verilecek
  function airdrop(uint256 _id) public {
    require(isStart, "did not start");
    require(otta.balanceOf(address(this)) != 0, "Mesh supply zero");
    require(_id<=4000,"only ");
    //id kontrolü yapılıcak - 4000 den küçük olmalı
    require(mesh.ownerOf(_id) == msg.sender, "take airdrop");
    require(mesh.balanceOf(msg.sender) != 0, "not has airdrop");
    require(!isAirDrop[msg.sender][_id], "taked");
    isAirDrop[msg.sender][_id] = true;
    otta.transfer(msg.sender, 125*10**18); // 125 otta - bir nft için
  }


  function setStartTime(bool _isStart) public {
    require(msg.sender==owner, "only owner");
    isStart = _isStart;
  }

}
