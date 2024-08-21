import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-web3-v4";
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  allowUnlimitedContractSize: true,
  solidity: {
    version: "0.8.21",
    settings: {
      evmVersion: "london",
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
    polygon_testnet: {
      url: "https://polygon-zkevm-cardona.blockpi.network/v1/rpc/public",
      accounts: [process.env.TESTNET_DEPLOYER_PRIVATE_KEY],
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY],
    },
    testnet: {
      url: "https://test-rpc.vitruveo.xyz",
      accounts: [
        process.env.TESTNET_DEPLOYER_PRIVATE_KEY,
        process.env.USER1_PRIVATE_KEY,
      ],
    },
    local: {
      url: "http://127.0.0.1:8545/",
      accounts: [process.env.LOCAL_DEPLOYER_PRIVATE_KEY],
    },
    mainnet: {
      url: "https://rpc.vitruveo.xyz",
      accounts: [process.env.MAINNET_DEPLOYER_PRIVATE_KEY],
    },
  },
};
