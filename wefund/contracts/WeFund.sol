// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeFund is Ownable {
    enum TokenType {
        USDC,
        USDT,
        BUSD
    }

    enum ProjectStatus {
        DocumentValuation,
        IntroCall,
        IncubationGoalSetup,
        IncubationGoal,
        MilestoneSetup,
        CrowdFundraising,
        MilestoneRelease,
        Completed
    }

    struct IncubationGoalInfo {
        string title;
        string description;
        string start_date;
        string end_date;
        uint256 approved_date;
    }

    struct BackerInfo {
        address addr;
        uint256 usdc_amount;
        uint256 usdt_amount;
        uint256 busd_amount;
        uint256 wfd_amount;
    }

    struct MilestoneInfo {
        uint256 step;
        string name;
        string description;
        string start_date;
        string end_date;
        uint256 amount;
    }

    struct Vote {
        address addr;
        bool vote;
    }

    struct ProjectInfo {
        uint256 id;
        address owner;
        uint256 collected;
        uint256 backed;
        ProjectStatus status;
        IncubationGoalInfo[] incubationGoals;
        uint256 incubationGoalVoteIndex;
        Vote[] wefundVotes;
        BackerInfo[] backers;
        MilestoneInfo[] milestones;
        Vote[] backerVotes;
        uint256 milestoneVotesIndex;
        bool rejected;
    }

    event CommunityAdded(uint256 length);
    event CommunityRemoved(uint256 length);
    event ProjectAdded(uint256 pid);
    event ProjectRemoved(uint256 pid);
    event DocumentValuationVoted(bool voted);
    event ProjectStatusChanged(ProjectStatus status);
    event IntroCallVoted(bool voted);
    event IncubationGoalSetupVoted(bool voted);
    event IncubationGoalAdded(uint256 length);
    event IncubationGoalRemoved(uint256 length, uint256 index);
    event IncubationGoalVoted(bool voted);
    event NextIncubationGoalVoting(uint256 index);
    event MilestoneAdded(uint256 length);
    event MilestoneRemoved(uint256 length, uint256 index);
    event MilestoneSetupVoted(bool voted);
    event NextMilestoneSetupVoting(uint256 index);
    event Backed(TokenType token, uint256 amount);
    event MilestoneReleaseVoted(bool voted);
    event NextMilestoneReleaseVoting(uint256 index);

    address USDC;
    address USDT;
    address BUSD;
    address WEFUND_WALLET;

    mapping(uint256 => ProjectInfo) private projects;
    uint256 private project_id;
    address[] private community;
    uint256 private wefund_id;

    constructor() {
        project_id = 1;
    }

    function setAddress(
        address _usdc,
        address _usdt,
        address _busd,
        address _wefund
    ) public onlyOwner {
        USDC = _usdc;
        USDT = _usdt;
        BUSD = _busd;
        WEFUND_WALLET = _wefund;
    }

    function setWefundID(uint256 _pid) public onlyOwner {
        wefund_id = _pid;
    }

    function addCommunity(address _addr) public onlyOwner {
        for (uint256 i = 0; i < community.length; i++) {
            if (community[i] == _addr) revert("Already Registered");
        }
        community.push(_addr);
        emit CommunityAdded(community.length);
    }

    function removeCommunity(address _addr) public onlyOwner {
        for (uint256 i = 0; i < community.length; i++)
            if (community[i] == _addr) {
                community[i] = community[community.length - 1];
                community.pop();
            }

        emit CommunityRemoved(community.length);
    }

    function addProjectByOwner(
        uint256 _collected,
        ProjectStatus _status,
        MilestoneInfo[] calldata _milestone
    ) public onlyOwner {
        ProjectInfo storage project = projects[project_id];
        project.id = project_id;
        project.owner = msg.sender;
        project.collected = _collected;
        project.status = _status;
        for (uint8 i = 0; i < _milestone.length; i++) project.milestones.push(_milestone[i]);
        project_id++;

        emit ProjectAdded(project_id);
    }

    function addProject(uint256 _collected) public {
        ProjectInfo storage project = projects[project_id];
        project.id = project_id;
        project.owner = msg.sender;
        project.collected = _collected;
        project_id++;

        emit ProjectAdded(project_id);
    }

    function removeProject(uint256 _pid) public onlyOwner {
        delete projects[_pid];

        emit ProjectRemoved(project_id);
    }

    function _getWefundWalletIndex(address _addr) internal view returns (uint8) {
        for (uint8 i = 0; i < community.length; i++) {
            if (community[i] == _addr) {
                return i;
            }
        }
        return type(uint8).max;
    }

    function _getWefundVoteIndex(uint256 pid, address _addr) internal view returns (uint8) {
        for (uint8 i = 0; i < projects[pid].wefundVotes.length; i++) {
            if (projects[pid].wefundVotes[i].addr == _addr) {
                return i;
            }
        }
        return type(uint8).max;
    }

    function _onlyWeFund() internal view {
        require(_getWefundWalletIndex(msg.sender) != type(uint8).max, "Only Wefund");
    }

    function _onlyProjectOwner(uint256 pid) internal view {
        require(projects[pid].owner == msg.sender, "Only Project Owner");
    }

    function _checkStatus(uint256 pid, ProjectStatus status) internal view {
        require(projects[pid].status == status, "Invalid Project Status");
    }

    function _wefundVote(uint256 pid, bool vote) internal {
        _onlyWeFund();

        ProjectInfo storage project = projects[pid];
        uint8 index = _getWefundVoteIndex(pid, msg.sender);
        if (index != type(uint8).max) project.wefundVotes[index].vote = vote;
        else project.wefundVotes.push(Vote({addr: msg.sender, vote: vote}));
    }

    function _isWefundAllVoted(uint256 pid) internal returns (bool) {
        ProjectInfo storage project = projects[pid];
        if (community.length <= project.wefundVotes.length) {
            for (uint8 i = 0; i < community.length; i++) {
                uint8 index = _getWefundVoteIndex(pid, community[i]);
                if (project.wefundVotes[index].vote == false) {
                    project.rejected = true;
                    return false;
                }
            }
            project.rejected = false;
            return true;
        }
        return false;
    }

    function documentValuationVote(uint256 pid, bool vote) public {
        _checkStatus(pid, ProjectStatus.DocumentValuation);
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            project.status = ProjectStatus.IntroCall;
            emit ProjectStatusChanged(ProjectStatus.IntroCall);
        }
        emit DocumentValuationVoted(vote);
    }

    function introCallVote(uint256 pid, bool vote) public {
        _checkStatus(pid, ProjectStatus.IntroCall);
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            project.status = ProjectStatus.IncubationGoalSetup;
            emit ProjectStatusChanged(ProjectStatus.IncubationGoalSetup);
        }
        emit IntroCallVoted(vote);
    }

    function incubationGoalSetupVote(uint256 pid, bool vote) public {
        _checkStatus(pid, ProjectStatus.IncubationGoalSetup);
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            project.status = ProjectStatus.IncubationGoal;
            emit ProjectStatusChanged(ProjectStatus.IncubationGoal);
        }
        emit IncubationGoalSetupVoted(vote);
    }

    function addIncubationGoal(uint256 pid, IncubationGoalInfo calldata _info) public {
        _onlyProjectOwner(pid);
        ProjectInfo storage project = projects[pid];
        project.incubationGoals.push(_info);
        emit IncubationGoalAdded(project.incubationGoals.length);
    }

    function removeIncubationGoal(uint256 pid, uint256 _index) public {
        _onlyProjectOwner(pid);
        ProjectInfo storage project = projects[pid];
        for (uint256 i = _index; i < project.incubationGoals.length - 1; i++) {
            project.incubationGoals[i] = project.incubationGoals[i + 1];
        }
        project.incubationGoals.pop();
        emit IncubationGoalRemoved(project.incubationGoals.length, _index);
    }

    function incubationGoalVote(uint256 pid, bool vote) public {
        _checkStatus(pid, ProjectStatus.IncubationGoal);
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            project.incubationGoals[project.incubationGoalVoteIndex].approved_date = block.timestamp;

            if (project.incubationGoalVoteIndex < project.incubationGoals.length - 1) {
                project.incubationGoalVoteIndex++;
                emit NextIncubationGoalVoting(project.incubationGoalVoteIndex);
            } else {
                project.status = ProjectStatus.MilestoneSetup;
                emit ProjectStatusChanged(ProjectStatus.MilestoneSetup);
            }
        }
        emit IncubationGoalVoted(vote);
    }

    function addMilestone(uint256 pid, MilestoneInfo calldata _info) public {
        _onlyProjectOwner(pid);
        ProjectInfo storage project = projects[pid];
        project.milestones.push(_info);
        emit MilestoneAdded(project.milestones.length);
    }

    function removeMilestone(uint256 pid, uint256 _index) public {
        _onlyProjectOwner(pid);
        ProjectInfo storage project = projects[pid];
        for (uint256 i = _index; i < project.milestones.length - 1; i++) {
            project.milestones[i] = project.milestones[i + 1];
        }
        project.milestones.pop();
        emit MilestoneRemoved(project.milestones.length, _index);
    }

    function milestoneSetupVote(uint256 pid, bool vote) public {
        _checkStatus(pid, ProjectStatus.MilestoneSetup);
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            if (project.milestoneVotesIndex < project.milestones.length - 1) {
                project.milestoneVotesIndex++;
                emit NextMilestoneSetupVoting(project.milestoneVotesIndex);
            } else {
                project.milestoneVotesIndex = 0;
                project.status = ProjectStatus.CrowdFundraising;
                emit ProjectStatusChanged(ProjectStatus.CrowdFundraising);
            }
        }
        emit MilestoneSetupVoted(vote);
    }

    function back(
        uint256 pid,
        TokenType token_type,
        uint256 amount,
        uint256 wfd_amount
    ) public {
        _checkStatus(pid, ProjectStatus.CrowdFundraising);

        address sender = msg.sender;

        ERC20 token;
        uint256 a_usdc = 0;
        uint256 a_usdt = 0;
        uint256 a_busd = 0;

        if (token_type == TokenType.USDC) {
            token = ERC20(USDC);
            a_usdc = amount / 10**token.decimals();
        } else if (token_type == TokenType.USDT) {
            token = ERC20(USDT);
            a_usdt = amount / 10**token.decimals();
        } else {
            token = ERC20(BUSD);
            a_busd = amount / 10**token.decimals();
        }
        token.transferFrom(sender, WEFUND_WALLET, amount);

        ProjectInfo storage project = projects[pid];
        project.backed += a_usdc + a_usdt + a_busd;

        bool b_exist = false;
        for (uint256 i = 0; i < project.backers.length; i++) {
            if (project.backers[i].addr == sender) {
                project.backers[i].usdc_amount += a_usdc;
                project.backers[i].usdt_amount += a_usdt;
                project.backers[i].busd_amount += a_busd;
                project.backers[i].wfd_amount += wfd_amount;
                b_exist = true;
                break;
            }
        }
        if (!b_exist) {
            project.backers.push(
                BackerInfo({
                    addr: sender,
                    usdc_amount: a_usdc,
                    usdt_amount: a_usdt,
                    busd_amount: a_busd,
                    wfd_amount: wfd_amount
                })
            );
        }
        if (project.backed >= project.collected) {
            project.status = ProjectStatus.MilestoneRelease;
            emit ProjectStatusChanged(ProjectStatus.MilestoneRelease);
        }

        emit Backed(token_type, amount);
    }

    function _getBackerIndex(uint256 pid, address _addr) public view returns (uint8) {
        ProjectInfo memory project = projects[pid];
        for (uint8 i = 0; i < project.backers.length; i++) {
            if (project.backers[i].addr == _addr) {
                return i;
            }
        }
        return type(uint8).max;
    }

    function _getBackerVoteIndex(uint256 pid, address _addr) internal view returns (uint8) {
        ProjectInfo memory project = projects[pid];
        for (uint8 i = 0; i < project.backerVotes.length; i++) {
            if (project.backerVotes[i].addr == _addr) {
                return i;
            }
        }
        return type(uint8).max;
    }

    modifier onlyBacker(uint256 pid) {
        require(_getBackerIndex(pid, msg.sender) != type(uint8).max, "Only Backer");
        _;
    }

    function _backerVote(uint256 pid, bool vote) internal {
        ProjectInfo storage project = projects[pid];
        uint8 index = _getBackerVoteIndex(pid, msg.sender);
        if (index != type(uint8).max) project.backerVotes[index].vote = vote;
        else project.backerVotes.push(Vote({addr: msg.sender, vote: vote}));
    }

    function _isBackerAllVoted(uint256 pid) internal returns (bool) {
        ProjectInfo storage project = projects[pid];
        if (project.backers.length <= project.backerVotes.length) {
            for (uint8 i = 0; i < project.backers.length; i++) {
                uint8 index = _getBackerVoteIndex(pid, project.backers[i].addr);
                if (project.backerVotes[index].vote == false) {
                    project.rejected = true;
                    return false;
                }
            }
            project.rejected = false;
            return true;
        }
        return false;
    }

    function milestoneReleaseVote(uint256 pid, bool vote) public onlyBacker(pid) {
        _checkStatus(pid, ProjectStatus.MilestoneRelease);
        _backerVote(pid, vote);
        if (_isBackerAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.backerVotes;
            if (project.milestoneVotesIndex < project.milestones.length - 1) {
                ERC20 token;
                token = ERC20(USDC);

                token.transferFrom(
                    WEFUND_WALLET,
                    project.owner,
                    project.milestones[project.milestoneVotesIndex].amount * 10**token.decimals()
                );

                project.milestoneVotesIndex++;
                emit NextMilestoneReleaseVoting(project.milestoneVotesIndex);
            } else {
                project.status = ProjectStatus.Completed;
                emit ProjectStatusChanged(ProjectStatus.Completed);
            }
        }
        emit MilestoneReleaseVoted(vote);
    }

    function getCommunity() public view returns (address[] memory) {
        return community;
    }

    function getNumberOfProjects() public view returns (uint256) {
        return project_id - 1;
    }

    function getProjectInfo() public view returns (ProjectInfo[] memory) {
        ProjectInfo[] memory info = new ProjectInfo[](project_id - 1);
        for (uint256 i = 1; i < project_id; i++) {
            info[i - 1] = projects[i];
        }
        return info;
    }
}
