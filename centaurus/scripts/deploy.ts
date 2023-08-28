import { ethers, network } from "hardhat";

const currentNetwork = network.name;
console.log(currentNetwork);

const main = async () => {
  const WeFund = await ethers.getContractFactory("WeFund");
  const wefund = await WeFund.deploy();
  await wefund.deployed();
  console.log("WeFund deployed to:", wefund.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
