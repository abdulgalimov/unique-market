import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: {},
    uniquerc: {
      url: "https://rpc.unq.uniq.su",
      accounts: [
        `0x5dd0164945e470e8255f6c575b6e1ffdaa3b0e7505694e1e38b13fb0b422c32b`,
        `0xb2c962f60f5f4f5b34091273979548f01624a2ae7e6cead145af813977abc290`,
      ],
    },
    opal: {
      url: "https://rpc-opal.unique.network",
      accounts: [
        `0x5dd0164945e470e8255f6c575b6e1ffdaa3b0e7505694e1e38b13fb0b422c32b`,
        `0xb2c962f60f5f4f5b34091273979548f01624a2ae7e6cead145af813977abc290`,
      ],
    },
  },
  mocha: {
    timeout: 100000000,
  },
};

export default config;
