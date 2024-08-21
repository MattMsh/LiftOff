import { log } from "console";
import { ethers, web3 } from "hardhat";

// const localAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const ownerAddress = "0x650f14051E298EDC44dD7260f0E1d2a652457059";
const factoryAddress = "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318";

const tokenData = {
  name: "Token",
  ticker: "TKN",
  description: "token description",
  image: "image url",
  totalSupply: ethers.parseEther("1000000"),
};

async function main() {
  const owner = await ethers.getSigner(ownerAddress);
  const poolFactory = await ethers.getContractAt(
    "PoolFactory",
    factoryAddress,
    owner
  );

  //@ts-ignore
  poolFactory.once("PoolCreated", async (address) => {
    console.log(`Pool deployed at: ${address}`);
    console.log(
      `Factory balance ${await ethers.provider.getBalance(poolFactory)}`
    );
    const pool = await ethers.getContractAt("LiquidityPool", address);
    console.log(`Token deployed at: ${await pool.getTokenAddress()}`);
  });

  //@ts-ignore
  // poolFactory.on("TransferedVTRU", async (to, amount, data) => {
  //   console.log({
  //     to,
  //     amount,
  //     data,
  //   });
  // });

  //@ts-ignore
  // poolFactory.once("TokenBought", (res) => {
  //   console.log("Log from factory Listener");
  //   console.log(res);
  // });

  const { name, ticker, description, image, totalSupply } = tokenData;

  try {
    await poolFactory.createPoolWithToken(
      name,
      ticker,
      description,
      image,
      totalSupply,
      {
        value: ethers.parseEther("0.1"),
        // gasPrice: 4,
        gasLimit: "30000000",
      }
    );
  } catch (e) {
    console.log(e as any);
  }
}

async function test() {
  console.log(
    await ethers.provider.getBalance(
      "0x8aCd85898458400f7Db866d53FCFF6f0D49741FF"
    )
  );
  console.log(
    await (
      await ethers.getContractAt(
        "Token",
        "0xe4c278D321184BBFFB72e4e59e16a953b6863BEF"
      )
    ).balanceOf("0x8aCd85898458400f7Db866d53FCFF6f0D49741FF")
  );
}

main();
