import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenData = {
  name: "Token",
  ticker: "TKN",
  description: "token description",
  image: "image url",
};

const TokenModule = buildModule("TokenModule", (m) => {
  const { name, ticker, description, image } = tokenData;
  const token = m.contract("Token", [name, ticker, description, image]);

  return { token };
});

module.exports = TokenModule;
