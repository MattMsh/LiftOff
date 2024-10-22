//@ts-nocheck

import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-web3-v4";
import { mine } from "@nomicfoundation/hardhat-network-helpers";
require("dotenv").config();

const abi = [
  {
    type: "event",
    name: "AdminChanged",
    inputs: [
      {
        type: "address",
        name: "previousAdmin",
        internalType: "address",
        indexed: false,
      },
      {
        type: "address",
        name: "newAdmin",
        internalType: "address",
        indexed: false,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Approval",
    inputs: [
      {
        type: "address",
        name: "owner",
        internalType: "address",
        indexed: true,
      },
      {
        type: "address",
        name: "spender",
        internalType: "address",
        indexed: true,
      },
      {
        type: "uint256",
        name: "value",
        internalType: "uint256",
        indexed: false,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "BeaconUpgraded",
    inputs: [
      {
        type: "address",
        name: "beacon",
        internalType: "address",
        indexed: true,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Initialized",
    inputs: [
      { type: "uint8", name: "version", internalType: "uint8", indexed: false },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleAdminChanged",
    inputs: [
      { type: "bytes32", name: "role", internalType: "bytes32", indexed: true },
      {
        type: "bytes32",
        name: "previousAdminRole",
        internalType: "bytes32",
        indexed: true,
      },
      {
        type: "bytes32",
        name: "newAdminRole",
        internalType: "bytes32",
        indexed: true,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleGranted",
    inputs: [
      { type: "bytes32", name: "role", internalType: "bytes32", indexed: true },
      {
        type: "address",
        name: "account",
        internalType: "address",
        indexed: true,
      },
      {
        type: "address",
        name: "sender",
        internalType: "address",
        indexed: true,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleRevoked",
    inputs: [
      { type: "bytes32", name: "role", internalType: "bytes32", indexed: true },
      {
        type: "address",
        name: "account",
        internalType: "address",
        indexed: true,
      },
      {
        type: "address",
        name: "sender",
        internalType: "address",
        indexed: true,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Transfer",
    inputs: [
      { type: "address", name: "from", internalType: "address", indexed: true },
      { type: "address", name: "to", internalType: "address", indexed: true },
      {
        type: "uint256",
        name: "value",
        internalType: "uint256",
        indexed: false,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Unwrap",
    inputs: [
      {
        type: "address",
        name: "account",
        internalType: "address",
        indexed: true,
      },
      {
        type: "uint256",
        name: "amount",
        internalType: "uint256",
        indexed: false,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Upgraded",
    inputs: [
      {
        type: "address",
        name: "implementation",
        internalType: "address",
        indexed: true,
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Wrap",
    inputs: [
      {
        type: "address",
        name: "account",
        internalType: "address",
        indexed: true,
      },
      {
        type: "uint256",
        name: "amount",
        internalType: "uint256",
        indexed: false,
      },
    ],
    anonymous: false,
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "BASE_EPOCH_PERIOD",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "DECIMALS",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "bytes32", name: "", internalType: "bytes32" }],
    name: "DEFAULT_ADMIN_ROLE",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "EPOCH_BLOCKS",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "MINIMUM_WRAP_VTRU",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "bytes32", name: "", internalType: "bytes32" }],
    name: "SERVICE_ROLE",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "bytes32", name: "", internalType: "bytes32" }],
    name: "UPGRADER_ROLE",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "allowance",
    inputs: [
      { type: "address", name: "owner", internalType: "address" },
      { type: "address", name: "spender", internalType: "address" },
    ],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [{ type: "bool", name: "", internalType: "bool" }],
    name: "approve",
    inputs: [
      { type: "address", name: "spender", internalType: "address" },
      { type: "uint256", name: "amount", internalType: "uint256" },
    ],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "balanceOf",
    inputs: [{ type: "address", name: "account", internalType: "address" }],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "burn",
    inputs: [{ type: "uint256", name: "amount", internalType: "uint256" }],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "burnFrom",
    inputs: [
      { type: "address", name: "account", internalType: "address" },
      { type: "uint256", name: "amount", internalType: "uint256" },
    ],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
    ],
    name: "circuitBreakerInfo",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint8", name: "", internalType: "uint8" }],
    name: "decimals",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [{ type: "bool", name: "", internalType: "bool" }],
    name: "decreaseAllowance",
    inputs: [
      { type: "address", name: "spender", internalType: "address" },
      { type: "uint256", name: "subtractedValue", internalType: "uint256" },
    ],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "epochCurrent",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "epochCurrentBlock",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "epochNext",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "epochNextBlock",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "bytes32", name: "", internalType: "bytes32" }],
    name: "getRoleAdmin",
    inputs: [{ type: "bytes32", name: "role", internalType: "bytes32" }],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "grantRole",
    inputs: [
      { type: "bytes32", name: "role", internalType: "bytes32" },
      { type: "address", name: "account", internalType: "address" },
    ],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "bool", name: "", internalType: "bool" }],
    name: "hasRole",
    inputs: [
      { type: "bytes32", name: "role", internalType: "bytes32" },
      { type: "address", name: "account", internalType: "address" },
    ],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [{ type: "bool", name: "", internalType: "bool" }],
    name: "increaseAllowance",
    inputs: [
      { type: "address", name: "spender", internalType: "address" },
      { type: "uint256", name: "addedValue", internalType: "uint256" },
    ],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "initialize",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "payable",
    outputs: [],
    name: "mintAdmin",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "string", name: "", internalType: "string" }],
    name: "name",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "address", name: "", internalType: "address" }],
    name: "pairAddress",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "pause",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "priceByEpoch",
    inputs: [{ type: "uint256", name: "", internalType: "uint256" }],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "priceCurrent",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [
      { type: "uint256[]", name: "blockNumbers", internalType: "uint256[]" },
      { type: "uint256[]", name: "prices", internalType: "uint256[]" },
    ],
    name: "priceRange",
    inputs: [
      { type: "uint256", name: "startEpoch", internalType: "uint256" },
      { type: "uint256", name: "endEpoch", internalType: "uint256" },
    ],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "priceTrailing",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "bytes32", name: "", internalType: "bytes32" }],
    name: "proxiableUUID",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "recoverVTRU",
    inputs: [{ type: "uint256", name: "amount", internalType: "uint256" }],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "recoverVTRU",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "renounceRole",
    inputs: [
      { type: "bytes32", name: "role", internalType: "bytes32" },
      { type: "address", name: "account", internalType: "address" },
    ],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "resetUserPeriod",
    inputs: [{ type: "address", name: "account", internalType: "address" }],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "revokeRole",
    inputs: [
      { type: "bytes32", name: "role", internalType: "bytes32" },
      { type: "address", name: "account", internalType: "address" },
    ],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "setPairAddress",
    inputs: [
      { type: "address", name: "newPairAddress", internalType: "address" },
    ],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "bool", name: "", internalType: "bool" }],
    name: "supportsInterface",
    inputs: [{ type: "bytes4", name: "interfaceId", internalType: "bytes4" }],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "string", name: "", internalType: "string" }],
    name: "symbol",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "totalEpochResetBlock",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "totalEpochWrapped",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "totalSupply",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [{ type: "uint256", name: "", internalType: "uint256" }],
    name: "totalWrapped",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
    ],
    name: "totals",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [{ type: "bool", name: "", internalType: "bool" }],
    name: "transfer",
    inputs: [
      { type: "address", name: "to", internalType: "address" },
      { type: "uint256", name: "amount", internalType: "uint256" },
    ],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [{ type: "bool", name: "", internalType: "bool" }],
    name: "transferFrom",
    inputs: [
      { type: "address", name: "from", internalType: "address" },
      { type: "address", name: "to", internalType: "address" },
      { type: "uint256", name: "amount", internalType: "uint256" },
    ],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "unpause",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "unwrap",
    inputs: [{ type: "uint256", name: "amount", internalType: "uint256" }],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "unwrapAll",
    inputs: [],
  },
  {
    type: "function",
    stateMutability: "nonpayable",
    outputs: [],
    name: "upgradeTo",
    inputs: [
      { type: "address", name: "newImplementation", internalType: "address" },
    ],
  },
  {
    type: "function",
    stateMutability: "payable",
    outputs: [],
    name: "upgradeToAndCall",
    inputs: [
      { type: "address", name: "newImplementation", internalType: "address" },
      { type: "bytes", name: "data", internalType: "bytes" },
    ],
  },
  {
    type: "function",
    stateMutability: "view",
    outputs: [
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
      { type: "uint256", name: "", internalType: "uint256" },
    ],
    name: "userInfo",
    inputs: [{ type: "address", name: "account", internalType: "address" }],
  },
  {
    type: "function",
    stateMutability: "payable",
    outputs: [],
    name: "wrap",
    inputs: [],
  },
  { type: "receive", stateMutability: "payable" },
];

task("balance", "Prints an account's balance")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs, hre) => {
    const balance = await ethers.provider.getBalance(taskArgs.account);
    console.log(ethers.formatEther(balance), "ETH");
    // const pool = await ethers.getContractAt("LiquidityPool", taskArgs.account);
    // console.log(ethers.formatEther(await pool.getVtruBalance()), "ETH");
  });

task("transfer", "Prints an account's balance").setAction(
  async (taskArgs, hre) => {
    const impersonatedAddress = "0xAC51c04Cb72A5D0F56D71Baf3E2F2B28e6426922";
    console.log({ network });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [impersonatedAddress],
    });

    const [recipient] = await ethers.getSigners();
    const contract = await ethers.getContractAt(
      abi,
      "0x3ccc3F22462cAe34766820894D04a40381201ef9"
    );
    const impersonatedSigner = await ethers.getImpersonatedSigner(
      impersonatedAddress
    );

    const tx = await contract
      .connect(impersonatedSigner)
      .transfer(
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        BigInt("100000000000000000000")
      );
    // const receipt = await tx.wait();
    // console.log({ receipt });

    const balance = await contract.balanceOf(impersonatedSigner);
    console.log(balance);
    const balanceReceiver = await contract.balanceOf(
      "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    );
    console.log(balanceReceiver);

    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [impersonatedAddress],
    });

    // const pool = await ethers.getContractAt("LiquidityPool", taskArgs.account);
    // console.log(ethers.formatEther(await pool.getVtruBalance()), "ETH");
  }
);

task("buy", "Buy token")
  .addParam("pool", "The pool's address")
  .setAction(async (taskArgs) => {
    const pool = await ethers.getContractAt("LiquidityPool", taskArgs.pool);
    try {
      const tx = await pool["buyToken()"]({
        value: BigInt("100000000000000000"),
      });
      const res = await tx.wait();
      console.log(res);
    } catch (e) {
      console.log(e);
    }
  });

task("sell", "Sells token")
  .addParam("pool", "The pool's address")
  .setAction(async (taskArgs) => {
    const amount = BigInt("1000000000000000000");
    const pool = await ethers.getContractAt("LiquidityPool", taskArgs.pool);
    const token = await ethers.getContractAt(
      "Token",
      await pool.getTokenAddress()
    );
    await token.approve(taskArgs.pool, amount);
    await pool.sellToken(amount);
  });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.26",
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
      testnet: "empty",
      mainnet: "",
    },
    customChains: [
      {
        network: "testnet",
        chainId: 14333,
        urls: {
          apiURL: "https://test-explorer-new.vitruveo.xyz/api",
          browserURL: "https://test-explorer-new.vitruveo.xyz",
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
  defaultNetwork: "hardhat",
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
    // hardhat: {
    //   forking: {
    //     url: "https://rpc.vitruveo.xyz",
    //     blockNumber: 5459217,
    //   },
    //   chains: {
    //     1490: {
    //       hardforkHistory: {
    //         cancun: 5459217,
    //       },
    //     },
    //   },
    // },
  },
};
