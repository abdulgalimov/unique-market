import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { loadConfig } from "./scripts/config";

const appConfig = loadConfig();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: {},
    unq: {
      url: appConfig.unq.rpcUrl,
      accounts: appConfig.accounts,
    },
    opal: {
      url: appConfig.opal.rpcUrl,
      accounts: appConfig.accounts,
    },
  },
  mocha: {
    timeout: 100000000,
  },
};

export default config;
