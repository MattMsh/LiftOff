import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import PoolFactoryModule from "./PoolFactory";

const tokenData = {
  name: "MVTRU",
  ticker: "$VTRU",
  description: "Meme VTRU coin",
  image:
    "https://lavender-broad-mosquito-273.mypinata.cloud/ipfs/QmRBDuCH9E5iZY1CmUpQhqTi5XvgDUL9ezJ2K83eqLqht9",
  totalSupply: BigInt("1000000000000000000000000"),
};

const TokenModule = buildModule("TokenModule", (m) => {
  const { poolFactory } = m.useModule(PoolFactoryModule);

  const createPoolWithTokenCall = m.call(
    poolFactory,
    "createPoolWithToken",
    Object.values(tokenData),
    {
      value: BigInt("100000000000000001"),
    }
  );
  const poolAddress = m.readEventArgument(
    createPoolWithTokenCall,
    "PoolCreated",
    0
  );
  const tokenAddress = m.readEventArgument(
    createPoolWithTokenCall,
    "PoolCreated",
    1
  );
  const pool = m.contractAt("LiquidityPool", poolAddress);
  const token = m.contractAt("Token", tokenAddress);

  return { pool, token };
});

module.exports = TokenModule;
