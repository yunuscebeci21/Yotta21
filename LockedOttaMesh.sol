// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ILockedOttaMesh } from "./interfaces/ILockedOttaMesh.sol";

/// @title LockedOtta for mesh
/// @author Yotta21
contract LockedOttaMesh is ILockedOttaMesh {
  /* ================ State Variables ================== */
  /// @notice Importing otta token methods
  ERC20 private ottaToken;
  mapping(string => uint256) public meshMap;

  /* ================ Constructor ================== */
  constructor(address _ottaAddress) {
    require(_ottaAddress != address(0), "Zero address");
    ottaToken = ERC20(_ottaAddress);
    meshMap["Delegator"] = 30 * 10**18;
    meshMap["Coordinator"] = 30 * 10**18;
    meshMap["Groups"] = 40 * 10**18;
  }

  /* ================ Functions ================== */
  /// @notice Returning otta balance of this contract
  function getOttaAmount() public view returns (uint256) {
    uint256 _ottaAmount = ottaToken.balanceOf(address(this));
    return _ottaAmount;
  }

  function getMeshPercentage(string memory _name)
    external
    view
    override
    returns (uint256)
  {
    return meshMap[_name];
  }
}
