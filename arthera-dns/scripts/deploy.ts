import { ethers, network } from "hardhat";

const currentNetwork = network.name;
console.log(currentNetwork);

const main = async () => {
  const dnsFactory = await ethers.getContractFactory("ArtheraDns");
  const dns = await dnsFactory.deploy();
  await dns.deployed();
  console.log("DNS deployed to:", dns.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
