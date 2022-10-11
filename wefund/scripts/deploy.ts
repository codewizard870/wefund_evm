import { ethers, network } from "hardhat";
import config from "../config";

const currentNetwork = network.name;

const main = async () => {
  const WeFund = await ethers.getContractFactory("WeFund");

  const wefund = await WeFund.deploy();

  await wefund.deployed();
  console.log("WeFund deployed to:", wefund.address);

  await wefund.intiialize();

  if (currentNetwork == "testnet") {
  } else if (currentNetwork == "mainnet") {
  }
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
