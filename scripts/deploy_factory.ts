import { ethers } from "hardhat";

const ownerAddress = "0x650f14051E298EDC44dD7260f0E1d2a652457059";

const poolFactoryData = {
  deployFeeWallet: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  bankWallet: "0xe170EACD576BA8136439f8D8F4CE7F57Cb253d6f",
  airDropWallet: "0xBa7BB8a5987aD230C5B47a9D53753c8E8833bD4B",
  transactionFeeWallet: "0x5dE8857A7b3798E8e42F30712E4b40b0f42fDC75",
  gammaBurnWallet: "0xbC4627a3C967Db501c6Ae23698941373a4277187",
  deltaBurnWallet: "0xD26811AE946542D377ddFbBBC50ecED25c550686",
  contractPrice: ethers.parseEther("0.1"),
  vtruToLP: ethers.parseEther("0.05"),
};

async function main() {
  const owner = await ethers.getSigner(ownerAddress);
  const PoolFactory = await ethers.getContractFactory("PoolFactory", owner);
  const {
    deployFeeWallet,
    bankWallet,
    airDropWallet,
    transactionFeeWallet,
    gammaBurnWallet,
    deltaBurnWallet,
    contractPrice,
    vtruToLP,
  } = poolFactoryData;
  const poolFactory = await PoolFactory.deploy(
    deployFeeWallet,
    contractPrice,
    vtruToLP,
    bankWallet,
    airDropWallet,
    transactionFeeWallet,
    gammaBurnWallet,
    deltaBurnWallet
  );
  await poolFactory.waitForDeployment();
  console.log("PoolFactory deployed to:", await poolFactory.getAddress());
}

main();
