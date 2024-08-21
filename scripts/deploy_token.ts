import { ethers } from "hardhat";

const ownerAddress = "0x650f14051E298EDC44dD7260f0E1d2a652457059";

const tokenData = {
  name: "Token",
  ticker: "TKN",
  description: "token description",
  image: "image url",
};

async function main() {
  const owner = await ethers.getSigner(ownerAddress);
  const Token = await ethers.getContractFactory("Token", owner);

  const { name, ticker, description, image } = tokenData;

  const token = await Token.deploy(name, ticker, description, image);

  await token.waitForDeployment();
  console.log("Token deployed to:", await token.getAddress());
}

main();
