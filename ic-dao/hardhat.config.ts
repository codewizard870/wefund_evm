/* eslint-disable @typescript-eslint/no-unused-vars */
import type { HardhatUserConfig, NetworkUserConfig } from "hardhat/types";
// import "@oasisprotocol/sapphire-hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-truffle5";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "solidity-coverage";
import "dotenv/config";

import "@nomiclabs/hardhat-etherscan";

const polygonMumbai: NetworkUserConfig = {
  url: "https://matic-mumbai.chainstacklabs.com",
  chainId: 80001,
  accounts: [process.env.PK!],
};

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gas: 120000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
    },
    polygonMumbai
  },
  solidity: {
    version: "0.8.0",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 9999,
      },
      outputSelection: {
        "*": {
          "*": ["abi", "evm.bytecode", "evm.deployedBytecode", "metadata"],
        },
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  abiExporter: {
    path: "./data/abi",
    clear: true,
    flat: false,
  },
  etherscan: {
    apiKey: "QR2YIYFA919M449I4W9R31Z28TXN79IEQP",
  },
};

export default config;
