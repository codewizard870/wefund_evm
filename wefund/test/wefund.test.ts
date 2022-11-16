import { formatEther, parseEther } from "ethers/lib/utils";
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
  const backedUSDC = parseEther("30000000");
  const backedUSDT = parseEther("70000000");
  const backedBUSD = parseEther("10000000");

  before(async () => {
    mockUSDC = await MockERC20.new("USDC", "USDC", _totalInitSupply);
    mockUSDT = await MockERC20.new("USDT", "USDT", _totalInitSupply);
    mockBUSD = await MockERC20.new("BUSD", "BUSD", _totalInitSupply);

    wefund = await WeFund.new({ from: alice });
    await wefund.setAddress(mockUSDC.address, mockUSDT.address, mockBUSD.address, treasury);
    await wefund.setWefundID(0);
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

    await expectRevert(wefund.addCommunity(alice), "Already Registered");

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
    result = await wefund.addProject(100_000_000, { from: carol });
    expectEvent(result, "ProjectAdded", {
      pid: "2",
    });
    result = await wefund.addProject(200_000_000, { from: david });
    expectEvent(result, "ProjectAdded", {
      pid: "3",
    });

    result = await wefund.addProjectByOwner(200_000_000, "5", [], { from: alice });
    expectEvent(result, "ProjectAdded", {
      pid: "4",
    });

    result = await wefund.removeProject("4");
    expectEvent(result, "ProjectRemoved", {
      pid: "4"
    })
  });

  it("Document Valuation Vote", async () => {
    await expectRevert(wefund.documentValuationVote("1", true, { from: carol }), "Only Wefund");

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

    await expectRevert(wefund.documentValuationVote("1", true, { from: bob }), "Invalid Project Status");
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

  const goal1 = {
    title: "goal 1",
    description: "goal 1",
    start_date:"2022-1-1",
    end_date:"2022-12-31",
    approved_date: 0,
  }
  const goal2 = {
    title: "goal 2",
    description: "goal 2",
    start_date:"2022-1-1",
    end_date:"2022-12-31",
    approved_date: 0,
  }
  it("Add Incubation Goal from Project Owner", async () => {
    await expectRevert(wefund.addIncubationGoal("1", goal1, { from: alice }), "Only Project Owner");

    result = await wefund.addIncubationGoal("1", goal1, { from: carol });
    expectEvent(result, "IncubationGoalAdded", {
      length: "1",
    });

    result = await wefund.addIncubationGoal("1", goal2, { from: carol });
    expectEvent(result, "IncubationGoalAdded", {
      length: "2",
    });

    result = await wefund.removeIncubationGoal("1", "0", { from: carol });
    expectEvent(result, "IncubationGoalRemoved", {
      length: "1",
      index: "0"
    });

    result = await wefund.addIncubationGoal("1", goal2, { from: carol });
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
    await expectRevert(wefund.addMilestone("1", milestone, { from: alice }), "Only Project Owner");

    result = await wefund.addMilestone("1", milestone, { from: carol });
    expectEvent(result, "MilestoneAdded", {
      length: "1",
    });

    result = await wefund.addMilestone("1", milestone, { from: carol });
    expectEvent(result, "MilestoneAdded", {
      length: "2",
    });

    result = await wefund.removeMilestone("1", "0", {from: carol});
    expectEvent(result, "MilestoneRemoved", {
      length: "1",
      index: "0",
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
    mockUSDC.mintTokens(parseEther("100000000000"), { from: erin });
    mockUSDC.increaseAllowance(wefund.address, parseEther("100000000000"), { from: erin });

    mockBUSD.mintTokens(parseEther("100000000000"), { from: erin });
    mockBUSD.increaseAllowance(wefund.address, parseEther("100000000000"), { from: erin });

    mockUSDT.mintTokens(parseEther("100000000000"), { from: operator });
    mockUSDT.increaseAllowance(wefund.address, parseEther("100000000000"), { from: operator });

    mockUSDC.increaseAllowance(wefund.address, parseEther("100000000000"), { from: treasury });
    mockUSDT.increaseAllowance(wefund.address, parseEther("100000000000"), { from: treasury });
    mockBUSD.increaseAllowance(wefund.address, parseEther("100000000000"), { from: treasury });

    
    result = await wefund.back("1", "0", backedUSDC, "1", { from: erin });
    expectEvent(result, "Backed", {
      token: "0",
      amount: backedUSDC.toString(),
    });

    result = await wefund.back("1", "2", backedBUSD, "1", { from: erin });
    expectEvent(result, "Backed", {
      token: "2",
      amount: backedBUSD.toString(),
    });

    result = await wefund.back("1", "1", backedUSDT, "1", { from: operator });
    expectEvent(result, "Backed", {
      token: "1",
      amount: backedUSDT.toString(),
    });
    expectEvent(result, "ProjectStatusChanged", {
      status: "6",
    });
  });

  it("Milestone 1 Release Vote", async () => {
    await expectRevert(wefund.milestoneReleaseVote("1", true, { from: bob }), "Only Backer");

    result = await wefund.milestoneReleaseVote("1", false, { from: erin });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: false,
    });

    result = await wefund.milestoneReleaseVote("1", true, { from: operator });
    expectEvent(result, "MilestoneReleaseVoted", {
      voted: true,
    });

    result = await wefund.milestoneReleaseVote("1", true, { from: erin });
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
    assert.equal(result, "3");

    result = await wefund.getProjectInfo();
    const amount = backedUSDC.add(backedUSDT.add(backedBUSD));
    assert.equal(parseFloat(result[0].backed), parseFloat(formatEther(amount)));
  });
});
