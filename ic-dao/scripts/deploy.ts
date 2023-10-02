import { ethers, network } from "hardhat";

const currentNetwork = network.name;
console.log(currentNetwork);

const main = async () => {
  const daoFactory = await ethers.getContractFactory("Dao");
  const dao = await daoFactory.deploy();
  await dao.deployed();
  console.log("Dao deployed to:", dao.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
