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
  const WEFUND_CONTRACT = "0xc0B5941f7013336Db66b978d818CC3C189Be6860";
  const provider = new ethers.providers.JsonRpcProvider(CHAINS_CONFIG.bst_testnet.rpc);
  if (!pk) return;
  const signer = new ethers.Wallet(pk, provider);
  const contract = new ethers.Contract(WEFUND_CONTRACT, WEFUND_ABI.abi, signer);

  let res;
  // const USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  // const USDT = 0x55d398326f99059fF775485246999027B3197955;
  // const BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

  // bsc testnet
  const USDC = "0x64544969ed7EBf5f083679233325356EbE738930";
  const USDT = "0x337610d27c682E347C9cD60BD4b3b107C9d34dDd";
  const BUSD = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee";
  const WEFUND_WALLET = "0x09Bb243F4b7BF5952BB4196c6968D3453DBEf71c";

  // bsc mainnet
  // address constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  // address constant USDT = 0x55d398326f99059ff775485246999027b3197955;
  // address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

  // res = await contract.addCommunity("0xFFfCd0B404c3d8AE38Ea2966bAD5A75D5Ab6ce0F");
  // await res.wait();

  // res = await contract.addCommunity("0x0961B8b67CdA06f145f634A5F7c453A15E072C40");
  // await res.wait();

  //   res = await contract.setAddress(USDC, USDT, BUSD, WEFUND_WALLET);
  //   await res.wait();

  //   res = await contract.setWefundID(1);
  //   await res.wait();

  //   res = await contract.getProjectInfo();
  //   console.log(res);

  //   res = await contract.addProjectByOwner(600000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "600000", "0", []]]);
  //   await res.wait();
  //   console.log("1");

  //   res = await contract.addProjectByOwner(390000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "390000", "0", []]]);
  //   await res.wait();
  //   console.log("2");

  //   res = await contract.addProjectByOwner(250000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "250000", "0", []]]);
  //   await res.wait();
  //   console.log("3");

  //   res = await contract.addProjectByOwner(600000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "600000", "0", []]]);
  //   await res.wait();
  //   console.log("4");

  //   res = await contract.addProjectByOwner(120000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "120000", "0", []]]);
  //   await res.wait();
  //   console.log("5");

  //   res = await contract.addProjectByOwner(120000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "120000", "0", []]]);
  //   await res.wait();
  //   console.log("6");

  //   res = await contract.addProjectByOwner(4080000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "4080000", "0", []]]);
  //   await res.wait();
  //   console.log("7");

  //   res = await contract.addProjectByOwner(120000, "5", [[0, "1", "", "2022-03-1", "2022-03-31", "120000", "0", []]]);
  //   await res.wait();
  //   console.log("8");

  // res = await contract.addIncubationGoal("1", ["goal 1", "goal 1 description", "2022-1-1", "2022-1-3"]);
  // await res.wait();

  // res = await contract.addIncubationGoal("1", ["goal 2", "goal 2 description", "2022-1-1", "2022-1-3"]);
  // await res.wait();

  // res = await contract.addIncubationGoal("2", ["goal 1", "goal 1 description", "2022-1-1", "2022-1-3"]);
  // await res.wait();

  // res = await contract.addIncubationGoal("2", ["goal 2", "goal 2 description", "2022-1-1", "2022-1-3"]);
  // await res.wait();
}
main();
