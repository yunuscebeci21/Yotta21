// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IWeth } from "./external/IWeth.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IProtocolVault } from "./interfaces/IProtocolVault.sol";
import { IEthereumPool } from "./interfaces/IEthereumPool.sol";

/// @title ProtocolVault
/// @author Yotta21
contract ProtocolVault is IProtocolVault {
  /* ============ Events ================ */
  /// @notice An event thats emitted when ProtocolGradual contract address setting 
  event ProtocolGradualSetted(address _protocolGradualAddress);
  /// @notice An event thats emitted when EthereumPool contract address setting
  event EthPoolSetted(address _ethPoolAddress);

  /*============ State Variables ================ */

  // Address of contract creater
  address public owner;
  // Address of Gradual Reduction Contract
  address public protocolGradualAddress;
  // Address of Ethereum Pool Contact
  address public ethPoolAddress;
  // Address of wrapper ether
  address public wethAddress;
  // address of taum address
  address public taumAddress;
  // address of price contract
  address public priceAddress;
  // set state of protocol vault
  bool public isEthPoolSetted;
  bool public isProtocolGradualSetted;
  // Importing wrapped ether methods
  IWeth public weth;
  // importing eth pool methods
  IEthereumPool public ethPool;

  /*============ Modifiers ================ */
  /// @notice Throws if the sender is not Taum or ProtocolGradual
  modifier onlyProtocolContracts() {
    require(
      (msg.sender == taumAddress ||
        msg.sender == protocolGradualAddress),
      "Only Protocol"
    );
    _;
  }

  /*
   * Throws if the sender is not an owner of this contract
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only Owner");
    _;
  }

  /*============ Constructor ================ */
  constructor(address _weth, address _taumAddress) {
    owner = msg.sender;
    require(_weth != address(0), "Zero address");
    wethAddress = _weth;
    weth = IWeth(wethAddress);
    require(_taumAddress != address(0), "Zero address");
    taumAddress = _taumAddress;
  }

  /*================= Functions=================*/
  receive() external payable {}

  /*================= External Functions=================*/
  /// @inheritdoc IProtocolVault
  function withdraw(address payable _account, uint256 _withdrawAmount)
    external
    override
    onlyProtocolContracts
    returns (bool state)
  {
    weth.withdraw(_withdrawAmount);
    _account.transfer(_withdrawAmount);
    emit WithdrawToAccount(_account, _withdrawAmount);
    return (true);
  }

  /// @inheritdoc IProtocolVault
  function feedPool(uint256 _amount) external override returns (bool) {
    require(msg.sender == protocolGradualAddress, "Only Protocol Gradual");
    bool _successTransfer = weth.transfer(ethPoolAddress, _amount);
    require(_successTransfer, "Transfer failed.");
    ethPool.addLimit(_amount);
    emit PoolFeeded(ethPoolAddress, _amount);
    return true;
  }

  /*================= Public Functions=================*/
  /// @notice Setting ProtocolGradual address only once
  /// @param _protocolGradualAddress The address of ProtocolGradual contract
  function setProtocolGradual(address _protocolGradualAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isProtocolGradualSetted, "Already setted");
    require(_protocolGradualAddress != address(0), "Zero address");
    isProtocolGradualSetted = true;
    protocolGradualAddress = _protocolGradualAddress;
    emit ProtocolGradualSetted(protocolGradualAddress);
    return protocolGradualAddress;
  }

  /// @notice Setting EthereumPool address only once
  /// @param _ethPoolAddress The EthereumPool contract address.
  function setEthPool(address payable _ethPoolAddress)
    public
    onlyOwner
    returns (address)
  {
    require(!isEthPoolSetted, "Already setted");
    require(_ethPoolAddress != address(0), "Zero address");
    isEthPoolSetted = true;
    ethPoolAddress = _ethPoolAddress;
    ethPool = IEthereumPool(_ethPoolAddress);
    emit EthPoolSetted(ethPoolAddress);
    return (ethPoolAddress);
  }
}
