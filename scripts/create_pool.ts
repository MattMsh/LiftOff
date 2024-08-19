import { ethers } from "hardhat";

const ownerAddress = "0x650f14051E298EDC44dD7260f0E1d2a652457059";
const factoryAddress = "0xB87D5695727a435f10fdd7D56a3da57dEdC2e1BE";

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

  const { name, ticker, description, image, totalSupply } = tokenData;

  await poolFactory
    .connect(owner)
    .createPoolWithToken(name, ticker, description, image, totalSupply, {
      value: ethers.parseEther("0.3"),
    });
}

main();
