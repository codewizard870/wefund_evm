import { formatEther, parseEther } from "ethers/lib/utils";
import { artifacts, contract } from "hardhat";
import { assert, expect } from "chai";
import { BN, constants, expectEvent, expectRevert, time } from "@openzeppelin/test-helpers";

const NftToken = artifacts.require("./CentaurusNftToken.sol");
const Factory = artifacts.require("./CentaurusFactory.sol");

contract("Centaurus", ([alice, bob, carol, david, erin, operator, treasury, injector]) => {
  // VARIABLES
  const _totalInitSupply = parseEther("10000");

  // Contracts
  let factory;
  let timelock;
  let nftToken;

  before(async () => {
    nftToken = await NftToken.new({ from: alice });
    factory = await Factory.new({ from: alice });
    factory.createDao(nftToken.address, 2, "cnft", [
      ["council", ["all"], [alice]]
    ], { from: alice })
  });

  it("add dao", async () => {
    // result = await wefund.addCommunity(alice);
    // expectEvent(result, "CommunityAdded", {
    //   length: "1",
    // });

    // result = await wefund.addCommunity(bob);
    // expectEvent(result, "CommunityAdded", {
    //   length: "2",
    // });

    // await expectRevert(wefund.addCommunity(alice), "Already Registered");

    // result = await wefund.addCommunity(carol);
    // expectEvent(result, "CommunityAdded", {
    //   length: "3",
    // });

    // result = await wefund.removeCommunity(carol);
    // expectEvent(result, "CommunityRemoved", {
    //   length: "2",
    // });
  });

});
