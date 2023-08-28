// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockCompound.sol";
import "./CentaurusGovernor.sol";
import "./CentaurusBase.sol";
import "./Timelock.sol";

contract CentaurusFactory is Ownable, BaseContract {
  using SafeMath for uint256;

  struct DeployedDao {
    address owner;
    address daoAddress;
  }

  uint256 private daoId;
  DeployedDao[] public daos;
  mapping(address => mapping(address => bool)) public daoOwners;

  event DaoCreated(address user, string name, address daoAddress);
  
  constructor(){

  }

  function getDaos() external view returns (DeployedDao[] memory) {
    return daos;
  }
  
  function createDao(
    address _token, 
    uint256 _timelockDelay,
    string memory _category,
    RoleSerialization[] memory _roles
  )
    public
  {
    require(bytes(_category).length != 0, "Category can not be empty");

    Timelock timelock = new Timelock(_timelockDelay);

    DeployedDao memory _dao;
    CentaurusGovernor dao = new CentaurusGovernor(_token, ICompoundTimelock(timelock), _category, _roles);
    
    timelock.setAdmin(address(dao));
    
    _dao.owner = msg.sender;
    _dao.daoAddress = address(dao);
    daos.push(_dao);

    daoOwners[address(dao)][msg.sender] = true;

    emit DaoCreated(msg.sender, _category, _dao.daoAddress);
  }
}