import { ethers } from "ethers";
import fs from "fs";
// require("dotenv").config();
import dotenv from "dotenv";

const WEFUND_ABI = JSON.parse(fs.readFileSync("./artifacts/contracts/WeFund.sol/WeFund.json"));
dotenv.config();

const CHAINS_CONFIG = {
  rinkeby: {
    chainId: "0x4",
    chainName: "Rinkeby",
    rpc: "https://rpc.ankr.com/eth_rinkeby",
  },
  bst_testnet: {
    chainId: "0x61",
    chainName: "BSC testnet",
    rpc: "https://data-seed-prebsc-1-s1.binance.org:8545/",
  },
  bsc: {
    chainId: "0x38",
    chainName: "Binance Smart Chain",
    rpc: "https://bsc-dataseed4.binance.org",
  },
};

const pk = process.env.PK;

async function main() {
  const WEFUND_CONTRACT = "0x5423E494C39583bC8b1E16Eab3347f69B95d7695";
  const provider = new ethers.providers.JsonRpcProvider(CHAINS_CONFIG.bst_testnet.rpc);
  if (!pk) return;
  const signer = new ethers.Wallet(pk, provider);
  const contract = new ethers.Contract(WEFUND_CONTRACT, WEFUND_ABI.abi, signer);

  let res;
  //bsc testnet
  // address constant USDC = 0x64544969ed7EBf5f083679233325356EbE738930;
  // address constant USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
  // address constant BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
  // address constant WEFUND_WALLET = 0x0dC488021475739820271D595a624892264Ca641;

  //bsc mainnet
  // address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  // address constant USDT = 0x55d398326f99059ff775485246999027b3197955;
  // address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

  res = await contract.setTokenAddress(
    "0x64544969ed7EBf5f083679233325356EbE738930",
    "0x337610d27c682E347C9cD60BD4b3b107C9d34dDd",
    "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee"
  );
  console.log(res);
  await res.wait();

  res = await contract.getProjectInfo();
  console.log(res);

  res = await contract.addProject(600000, [[0, "1", "", "2022-03-1", "2022-03-31", "600000", "0", []]]);
  await res.wait();
  console.log("1");

  res = await contract.addProject(390000, [[0, "1", "", "2022-03-1", "2022-03-31", "390000", "0", []]]);
  await res.wait();
  console.log("2");

  res = await contract.addProject(250000, [[0, "1", "", "2022-03-1", "2022-03-31", "250000", "0", []]]);
  await res.wait();
  console.log("3");

  res = await contract.addProject(600000, [[0, "1", "", "2022-03-1", "2022-03-31", "600000", "0", []]]);
  await res.wait();
  console.log("4");

  res = await contract.addProject(120000, [[0, "1", "", "2022-03-1", "2022-03-31", "120000", "0", []]]);
  await res.wait();
  console.log("5");

  res = await contract.addProject(120000, [[0, "1", "", "2022-03-1", "2022-03-31", "120000", "0", []]]);
  await res.wait();
  console.log("6");

  res = await contract.addProject(4080000, [[0, "1", "", "2022-03-1", "2022-03-31", "4080000", "0", []]]);
  await res.wait();
  console.log("7");

  res = await contract.addProject(120000, [[0, "1", "", "2022-03-1", "2022-03-31", "120000", "0", []]]);
  await res.wait();
  console.log("8");
}
main();
