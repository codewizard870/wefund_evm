// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//bsc testnet
// address constant USDC = 0x686c626E48bfC5DC98a30a9992897766fed4Abd3;
// address constant USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
// address constant BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
// address constant WEFUND_WALLET = 0x0dC488021475739820271D595a624892264Ca641;

//bsc mainnet
// address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
// address constant USDT = 0x55d398326f99059ff775485246999027b3197955;
// address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

contract WeFund is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // AggregatorV3Interface internal priceFeed;
    //rinkeby
    address USDC = 0xFE724a829fdF12F7012365dB98730EEe33742ea2;
    address USDT = 0x6EE856Ae55B6E1A249f04cd3b947141bc146273c;
    address BUSD = 0x16c550a97Ad2ae12C0C8CF1CC3f8DB4e0c45238f;
    address WEFUND_WALLET = 0x0dC488021475739820271D595a624892264Ca641;

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
        string goal;
    }

    struct BackerInfo {
        address addr;
        uint256 usdc_amount;
        uint256 usdt_amount;
        uint256 busd_amount;
    }

    struct MilestoneInfo {
        uint256 step;
        string name;
        string description;
        string start_date;
        string end_date;
        uint256 amount;
        string status;
    }

    struct ProjectInfo {
        uint256 id;
        address owner;
        uint256 collected;
        uint256 backed;
        ProjectStatus status;
        IncubationGoalInfo[] incubationGoals;
        uint256 incubationGoalVoteIndex;
        address[] wefundVotes;
        BackerInfo[] backers;
        MilestoneInfo[] milestones;
        address[] backerVotes;
        uint256 milestoneVotesIndex;
    }
    mapping(uint256 => ProjectInfo) private projects;
    uint256 private project_id;
    address[] private community;

    event WhitelistAdded(address indexed addr);
    event WhitelistRemoved(address indexed addr);
    event ProjectAdded(uint256 indexed pid);

    function initialize() public initializer {
        project_id = 1;
        __Ownable_init();
    }

    function setTokenAddress(
        address _usdc,
        address _usdt,
        address _busd
    ) public onlyOwner {
        USDC = _usdc;
        USDT = _usdt;
        BUSD = _busd;
    }

    function addCommunity(address _addr) public {
        for (uint256 i = 0; i < community.length; i++) {
            if (community[i] == _addr) {
                revert("already registered");
            }
        }
        community.push(_addr);
    }

    function removeCommunity(address _addr) public {
        uint256 length = community.length;
        for (uint256 i = 0; i < length; i++) {
            if (community[i] == _addr) {
                community[i] = community[length - 1];
                community.pop();
            }
        }
    }

    function addProject(uint256 _collected, MilestoneInfo[] calldata _milestone) public {
        ProjectInfo storage project = projects[project_id];
        project.id = project_id;
        project.owner = msg.sender;
        project.collected = _collected;
        for (uint8 i = 0; i < _milestone.length; i++) project.milestones.push(_milestone[i]);
        project_id++;

        emit ProjectAdded(project_id);
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
        ProjectInfo memory project = projects[pid];
        for (uint8 i = 0; i < project.wefundVotes.length; i++) {
            if (project.wefundVotes[i] == _addr) {
                return i;
            }
        }
        return type(uint8).max;
    }

    modifier onlyWefund() {
        require(_getWefundWalletIndex(msg.sender) != type(uint8).max, "Only Wefund Wallet");
        _;
    }

    modifier onlyProjectOwner(uint256 pid) {
        ProjectInfo memory project = projects[pid];
        require(project.owner == msg.sender, "Only Project Owner");
        _;
    }

    modifier checkStatus(uint256 pid, ProjectStatus status) {
        ProjectInfo memory project = projects[pid];
        require(project.status == status, "Project Status is invalid");
        _;
    }

    function _wefundVote(uint256 pid, bool vote) internal {
        ProjectInfo storage project = projects[pid];
        uint8 index = _getWefundVoteIndex(pid, msg.sender);
        if (index != type(uint8).max) {
            if (vote == false) {
                uint256 length = project.wefundVotes.length;
                project.wefundVotes[index] = project.wefundVotes[length - 1];
                project.wefundVotes.pop();
            }
        } else {
            if (vote == true) {
                project.wefundVotes.push(msg.sender);
            }
        }
    }

    function _isWefundAllVoted(uint256 pid) internal view returns (bool) {
        for (uint8 i = 0; i < community.length; i++) {
            if (_getWefundVoteIndex(pid, community[i]) == type(uint8).max) {
                return false;
            }
        }
        return true;
    }

    function documentValuationVote(uint256 pid, bool vote)
        public
        onlyWefund
        checkStatus(pid, ProjectStatus.DocumentValuation)
    {
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            project.status = ProjectStatus.IntroCall;
        }
    }

    function introCallVote(uint256 pid, bool vote) public onlyWefund checkStatus(pid, ProjectStatus.IntroCall) {
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            project.status = ProjectStatus.IncubationGoalSetup;
        }
    }

    function incubationGoalSetupVote(uint256 pid, bool vote)
        public
        onlyWefund
        checkStatus(pid, ProjectStatus.IncubationGoalSetup)
    {
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            project.status = ProjectStatus.IncubationGoal;
        }
    }

    function addIncubationGoal(uint256 pid, IncubationGoalInfo calldata _info) public onlyProjectOwner(pid) {
        ProjectInfo storage project = projects[pid];
        project.incubationGoals.push(_info);
    }

    function incubationGoalVote(uint256 pid, bool vote)
        public
        onlyWefund
        checkStatus(pid, ProjectStatus.IncubationGoal)
    {
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            if (project.incubationGoalVoteIndex < project.incubationGoals.length - 1) {
                project.incubationGoalVoteIndex++;
            } else {
                project.status = ProjectStatus.MilestoneSetup;
            }
        }
    }

    function milestoneSetupVote(uint256 pid, bool vote)
        public
        onlyWefund
        checkStatus(pid, ProjectStatus.MilestoneSetup)
    {
        _wefundVote(pid, vote);
        if (_isWefundAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.wefundVotes;
            if (project.milestoneVotesIndex < project.milestones.length - 1) {
                project.milestoneVotesIndex++;
            } else {
                project.status = ProjectStatus.CrowdFundraising;
            }
        }
    }

    function back(
        uint256 pid,
        uint256 token_type,
        uint256 amount
    ) public checkStatus(pid, ProjectStatus.CrowdFundraising) {
        address sender = msg.sender;

        IERC20Upgradeable token;
        uint256 a_usdc = 0;
        uint256 a_usdt = 0;
        uint256 a_busd = 0;

        if (token_type == 0) {
            token = IERC20Upgradeable(USDC);
            a_usdc = amount;
        } else if (token_type == 1) {
            token = IERC20Upgradeable(USDT);
            a_usdt = amount;
        } else {
            token = IERC20Upgradeable(BUSD);
            a_busd = amount;
        }

        token.transferFrom(sender, WEFUND_WALLET, amount);

        ProjectInfo storage project = projects[pid];
        project.backed += amount;

        bool b_exist = false;
        for (uint256 i = 0; i < project.backers.length; i++) {
            if (project.backers[i].addr == sender) {
                project.backers[i].usdc_amount += a_usdc;
                project.backers[i].usdt_amount += a_usdt;
                project.backers[i].busd_amount += a_busd;
                b_exist = true;
                break;
            }
        }
        if (!b_exist) {
            project.backers.push(
                BackerInfo({addr: sender, usdc_amount: a_usdc, usdt_amount: a_usdt, busd_amount: a_busd})
            );
        }
        if (project.backed >= project.collected) {
            project.status = ProjectStatus.MilestoneRelease;
        }
    }

    function _getBackerIndex(uint256 pid, address _addr) internal view returns (uint8) {
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
            if (project.backerVotes[i] == _addr) {
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
        if (index != type(uint8).max) {
            //already voted
            if (vote == false) {
                uint256 length = project.backerVotes.length;
                project.backerVotes[index] = project.backerVotes[length - 1];
                project.backerVotes.pop();
            }
        } else {
            if (vote == true) {
                project.backerVotes.push(msg.sender);
            }
        }
    }

    function _isBackerAllVoted(uint256 pid) internal view returns (bool) {
        ProjectInfo memory project = projects[pid];
        for (uint8 i = 0; i < project.backers.length; i++) {
            if (_getBackerVoteIndex(pid, project.backers[i].addr) == type(uint8).max) {
                return false;
            }
        }
        return true;
    }

    function milestoneReleaseVote(uint256 pid, bool vote)
        public
        onlyBacker(pid)
        checkStatus(pid, ProjectStatus.MilestoneRelease)
    {
        _backerVote(pid, vote);
        if (_isBackerAllVoted(pid) == true) {
            ProjectInfo storage project = projects[pid];
            delete project.backerVotes;
            if (project.milestoneVotesIndex < project.milestones.length - 1) {
                IERC20Upgradeable token;
                token = IERC20Upgradeable(BUSD);

                token.transferFrom(
                    WEFUND_WALLET,
                    project.owner,
                    project.milestones[project.milestoneVotesIndex].amount
                );

                project.milestoneVotesIndex++;
            } else {
                project.status = ProjectStatus.Completed;
            }
        }
    }

    function getCommunity() public view returns (address[] memory) {
        return community;
    }

    function getNumberOfProjects() public view returns (uint256) {
        return project_id;
    }

    function getProjectInfo() public view returns (ProjectInfo[] memory) {
        ProjectInfo[] memory info = new ProjectInfo[](project_id - 1);
        for (uint256 i = 1; i < project_id; i++) {
            info[i - 1] = projects[i];
        }
        return info;
    }
}
