import { parseEther } from "ethers/lib/utils";
import { artifacts, contract } from "hardhat";
import { assert, expect } from "chai";
import { BN, constants, expectEvent, expectRevert, time } from "@openzeppelin/test-helpers";

const MockERC20 = artifacts.require("./utils/MockERC20.sol");
const WeFund = artifacts.require("./WeFund.sol");

const PRICE_BNB = 400;

function gasToBNB(gas: number, gwei = 5) {
  const num = gas * gwei * 10 ** -9;
  return num.toFixed(4);
}

function gasToUSD(gas: number, gwei = 5, priceBNB: number = PRICE_BNB) {
  const num = gas * priceBNB * gwei * 10 ** -9;
  return num.toFixed(2);
}

contract("WeFund", ([alice, bob, carol, david, erin, operator, treasury, injector]) => {
  // VARIABLES
  const _totalInitSupply = parseEther("10000");

  // Contracts
  let wefund;
  let mockUSDC;
  let mockUSDT;
  let mockBUSD;

  let result: any;
  const milestone = {
    step: "1",
    name: "Milestone1",
    description: "",
    start_date: "",
    end_date: "",
    amount: 20_000_000,
    status: "",
  };
  const back1 = 30_000_000;
  const back2 = 70_000_000;
  const back3 = 10_000_000;

  before(async () => {
    // Deploy MockCake
    mockUSDC = await MockERC20.new("USDC", "USDC", _totalInitSupply);
    mockUSDT = await MockERC20.new("USDT", "USDT", _totalInitSupply);
    mockBUSD = await MockERC20.new("BUSD", "BUSD", _totalInitSupply);

    // Deploy PancakeSwapLottery
    wefund = await WeFund.new({ from: alice });

    await wefund.setTokenAddress(mockUSDC.address, mockUSDT.address, mockBUSD.address);
    await wefund.setWefundwallet(treasury);

    mockUSDC.mintTokens(100_000_000_000, { from: erin });
    mockUSDC.increaseAllowance(wefund.address, 100_000_000_000, { from: erin });

    mockUSDC.mintTokens(100_000_000_000, { from: operator });
    mockUSDC.increaseAllowance(wefund.address, 100_000_000_000, { from: operator });

    mockUSDC.increaseAllowance(wefund.address, 100_000_000_000, { from: treasury });
  });

  it("Community add and remove", async () => {
    result = await wefund.addCommunity(alice);
    expectEvent(result, "CommunityAdded", {
      length: "1",
    });

    result = await wefund.addCommunity(bob);
    expectEvent(result, "CommunityAdded", {
      length: "2",
    });

    expectRevert(wefund.addCommunity(alice), "already registered");

    result = await wefund.addCommunity(carol);
    expectEvent(result, "CommunityAdded", {
      length: "3",
    });

    result = await wefund.removeCommunity(carol);
    expectEvent(result, "CommunityRemoved", {
      length: "2",
    });
  });
  it("Project Add", async () => {
    result = await wefund.addProject(100_000_000, [], { from: carol });
    expectEvent(result, "ProjectAdded", {
      pid: "2",
    });
    result = await wefund.addProject(200_000_000, [], { from: david });
    expectEvent(result, "ProjectAdded", {
      pid: "3",
    });
  });
  it("Document Valuation Vote", async () => {
    expectRevert(wefund.documentValuationVote("1", true, { from: carol }), "Only Wefund Wallet");

    result = await wefund.documentValuationVote("1", true, { from: alice });
    expectEvent(result, "DocumentValuationVoted", {
      voted: true,
    });

    result = await wefund.documentValuationVote("1", false, { from: bob });
    expectEvent(result, "DocumentValuationVoted", {
      voted: false,
    });

    result = await wefund.documentValuationVote("1", true, { from: bob });
    expectEvent(result, "ProjectStatusChanged", {
      status: "1",
    });

    expectRevert(wefund.documentValuationVote("1", true, { from: bob }), "Project Status is invalid");
  });

  it("Intro Call Vote", async () => {
    result = await wefund.introCallVote("1", true, { from: alice });
    expectEvent(result, "IntroCallVoted", {
      voted: true,
    });

    result = await wefund.introCallVote("1", false, { from: alice });
    expectEvent(result, "IntroCallVoted", {
      voted: false,
    });

    result = await wefund.introCallVote("1", true, { from: alice });
    expectEvent(result, "IntroCallVoted", {
      voted: true,
    });

    result = await wefund.introCallVote("1", true, { from: bob });
    expectEvent(result, "ProjectStatusChanged", {
      status: "2",
    });
  });

  it("Incubation Goal Setup Vote", async () => {
    result = await wefund.incubationGoalSetupVote("1", true, { from: alice });
    expectEvent(result, "IncubationGoalSetupVoted", {
      voted: true,
    });

    result = await wefund.incubationGoalSetupVote("1", true, { from: bob });
    expectEvent(result, "ProjectStatusChanged", {
      status: "3",
    });
  });

  it("Add Incubation Goal from Project Owner", async () => {
    expectRevert(wefund.addIncubationGoal("1", { goal: "GOAL 1" }, { from: alice }), "Only Project Owner");

    result = await wefund.addIncubationGoal("1", { goal: "GOAL 1" }, { from: carol });
    expectEvent(result, "IncubationGoalAdded", {
      length: "1",
    });

    result = await wefund.addIncubationGoal("1", { goal: "GOAL 2" }, { from: carol });
    expectEvent(result, "IncubationGoalAdded", {
      length: "2",
    });
  });

  it("Incubation Goal 1 Vote", async () => {
    result = await wefund.incubationGoalVote("1", true, { from: alice });
    expectEvent(result, "IncubationGoalVoted", {
      voted: true,
    });

    result = await wefund.incubationGoalVote("1", true, { from: bob });
    expectEvent(result, "IncubationGoalVoted", {
      voted: true,
    });
    expectEvent(result, "NextIncubationGoalVoting", {
      index: "1",
    });
  });

  it("Incubation Goal 2 Vote", async () => {
    result = await wefund.incubationGoalVote("1", true, { from: alice });
    expectEvent(result, "IncubationGoalVoted", {
      voted: true,
    });

    result = await wefund.incubationGoalVote("1", true, { from: bob });
    expectEvent(result, "IncubationGoalVoted", {
      voted: true,
    });
    expectEvent(result, "ProjectStatusChanged", {
      status: "4",
    });
  });

  it("Add Milestones from Project Owner", async () => {
    expectRevert(wefund.addMilestone("1", milestone, { from: alice }), "Only Project Owner");

    result = await wefund.addMilestone("1", milestone, { from: carol });
    expectEvent(result, "MilestoneAdded", {
      length: "1",
    });

    result = await wefund.addMilestone("1", milestone, { from: carol });
    expectEvent(result, "MilestoneAdded", {
      length: "2",
    });
  });

  it("Milestone 1 Setup Vote", async () => {
    result = await wefund.milestoneSetupVote("1", true, { from: alice });
    expectEvent(result, "MilestoneSetupVoted", {
      voted: true,
    });

    result = await wefund.milestoneSetupVote("1", true, { from: bob });
    expectEvent(result, "MilestoneSetupVoted", {
      voted: true,
    });
    expectEvent(result, "NextMilestoneSetupVoting", {
      index: "1",
    });
  });

  it("Milestone 2 Setup Vote", async () => {
    result = await wefund.milestoneSetupVote("1", true, { from: alice });
    expectEvent(result, "MilestoneSetupVoted", {
      voted: true,
    });

    result = await wefund.milestoneSetupVote("1", true, { from: bob });
    expectEvent(result, "MilestoneSetupVoted", {
      voted: true,
    });
    expectEvent(result, "ProjectStatusChanged", {
      status: "5",
    });
  });

  it("CrowdFunding", async () => {
    result = await wefund.back("1", "0", back1, { from: erin });
    expectEvent(result, "Backed", {
      token: "0",
      amount: back1.toString(),
    });

    result = await wefund.back("1", "0", back3, { from: erin });
    expectEvent(result, "Backed", {
      token: "0",
      amount: back3.toString(),
    });


    result = await wefund.back("1", "0", back2, { from: operator });
    expectEvent(result, "Backed", {
      token: "0",
      amount: back2.toString(),
    });
    expectEvent(result, "ProjectStatusChanged", {
      status: "6",
    });
  });

  it("Milestone 1 Release Vote", async () => {
    expectRevert(wefund.milestoneReleaseVote("1", true, {from: bob}), "Only Backer");

    result = await wefund.milestoneReleaseVote("1", true, { from: erin });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: true,
    });

    result = await wefund.milestoneReleaseVote("1", false, { from: erin });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: false,
    });

    result = await wefund.milestoneReleaseVote("1", true, { from: erin });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: true,
    });

    result = await wefund.milestoneReleaseVote("1", true, { from: operator });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: true,
    });

    expectEvent(result, "NextMilestoneReleaseVoting", {
      index: "1",
    });
  });

  it("Milestone 2 Release Vote", async () => {
    result = await wefund.milestoneReleaseVote("1", true, { from: erin });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: true,
    });

    result = await wefund.milestoneReleaseVote("1", true, { from: operator });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: true,
    });

    expectEvent(result, "ProjectStatusChanged", {
      status: "7",
    });
  });
  it("Community", async () => {
    result = await wefund.getCommunity();
    assert.equal(result.length, 2);
  });
  it("Project", async () => {
    result = await wefund.getNumberOfProjects();
    assert.equal(result, "2");

    result = await wefund.getProjectInfo();
    assert.equal(result[0].backed, back1 + back2+back3);
  });
});
