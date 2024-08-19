import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  allowUnlimitedContractSize: true,
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  sourcify: {
    enabled: false,
  },
  etherscan: {
    apiKey: {
      testnet: "",
      mainnet: "",
    },
    customChains: [
      {
        network: "testnet",
        chainId: 14333,
        urls: {
          apiURL: "https://test-explorer.vitruveo.xyz/api",
          browserURL: "https://www.vitruveo.xyz",
        },
      },
      {
        network: "mainnet",
        chainId: 1490,
        urls: {
          apiURL: "https://explorer.vitruveo.xyz/api",
          browserURL: "https://www.vitruveo.xyz",
        },
      },
    ],
  },
  networks: {
    testnet: {
      url: "https://test-rpc.vitruveo.xyz",
      accounts: [process.env.TESTNET_DEPLOYER_PRIVATE_KEY],
    },
    local: {
      url: "http://127.0.0.1:8545/",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    },
    mainnet: {
      url: "https://rpc.vitruveo.xyz",
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    },
  },
};
