// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockCompound.sol";
import "./CentaurusBase.sol";
import "./CentaurusNftToken.sol";
import "hardhat/console.sol";

contract CentaurusGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorTimelockCompound,
    BaseContract
{
    CentaurusNftToken public collection;
    mapping(string => Role) public roles;
    string[] public roleNames;
    string public category;

    uint256 constant QUORUM = 5;

    event MemberAdded(uint256 length);

    constructor(
        address _token,
        ICompoundTimelock _timelock,
        string memory _category,
        RoleSerialization[] memory _roles
    )
        Governor("MyGovernor")
        GovernorSettings(1 /* 1 block */, 9, 2)
        GovernorVotes(IVotes(_token))
        GovernorTimelockCompound(_timelock)
    {
        collection = CentaurusNftToken(_token);
        category = _category;
        for (uint256 i = 0; i < _roles.length; i++) {
            roleNames.push(_roles[i].name);

            Role storage role = roles[_roles[i].name];

            role.name = _roles[i].name;

            for (uint256 j = 0; j < _roles[i].members.length; j++) {
                role.members.push(_roles[i].members[j]);
            }

            for (uint256 j = 0; j < _roles[i].permission.length; j++) {
                role.permission[_roles[i].permission[j]] = true;
            }
        }
    }

    function getRole(address sender) public view returns (string memory) {
        bool bAuth = false;
        string memory _role = "";
        for (uint256 i = 0; i < roleNames.length; i++) {
            for (uint256 j = 0; j < roles[roleNames[i]].members.length; j++) {
                if (roles[roleNames[i]].members[j] == sender) {
                    bAuth = true;
                    _role = roleNames[i];
                }
            }
        }
        require(bAuth, "Not member");
        return _role;
    }

    modifier onlyRightMember(address _sender, string memory _permissionType) {
        string memory role = getRole(msg.sender);
        require(roles[role].permission["all"] || roles[role].permission[_permissionType], "Not right");
        _;
    }

    function addMember(address _member, string memory role) public {
        OnChainMetadata[] memory metadatas = collection.metadatasOfOwner(_member);
        bool bAuth = false;
        for (uint256 i = 0; i < metadatas.length; i++) {
            OnChainMetadata memory _metadata = metadatas[i];
            if (compareStrings(_metadata.category, category) && compareStrings(_metadata.subCategory, role)) {
                bAuth = true;
                break;
            }
        }
        require(bAuth, "Have to keep the right token");

        address[] storage members = roles[role].members;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) revert("Already Registered");
        }
        members.push(_member);
        emit MemberAdded(members.length);
    }

    function getTotalVotes(uint256 proposalId) internal view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < roleNames.length; i++) sum += roles[roleNames[i]].members.length;
        return sum;
    }
    
    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 3;
    }

    function _quorumReached(
        uint256 proposalId
    ) internal view override(Governor, GovernorCountingSimple) returns (bool) {
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = proposalVotes(proposalId);

        return (getTotalVotes(proposalId) * QUORUM) / 10 <= forVotes + abstainVotes;
    }

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function state(
        uint256 proposalId
    ) public view override(Governor, GovernorTimelockCompound) returns (ProposalState) {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) onlyRightMember(msg.sender, "propose") returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function castVote(
        uint256 proposalId,
        uint8 support
    ) public override(Governor, IGovernor) onlyRightMember(msg.sender, "vote") returns (uint256) {
        return super.castVote(proposalId, support);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockCompound) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockCompound) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockCompound) returns (address) {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor, GovernorTimelockCompound) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
