import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const poolFactoryData = {
  deployFeeWallet: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  contractPrice: BigInt("100000000000000000"),
  vtruToLP: BigInt("50000000000000000"),
  bankWallet: "0xe170EACD576BA8136439f8D8F4CE7F57Cb253d6f",
  airDropWallet: "0xBa7BB8a5987aD230C5B47a9D53753c8E8833bD4B",
  transactionFeeWallet: "0x5dE8857A7b3798E8e42F30712E4b40b0f42fDC75",
  gammaBurnWallet: "0xbC4627a3C967Db501c6Ae23698941373a4277187",
  deltaBurnWallet: "0xD26811AE946542D377ddFbBBC50ecED25c550686",
};

const PoolFactoryModule = buildModule("PoolFactoryModule", (m) => {
  const poolFactory = m.contract("PoolFactory", Object.values(poolFactoryData));

  return { poolFactory };
});

export default PoolFactoryModule;
